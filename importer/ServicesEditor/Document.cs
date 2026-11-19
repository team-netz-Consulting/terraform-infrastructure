using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Json.Schema;

namespace ServicesEditor;

public sealed class ServiceDocument
{
    private static readonly JsonSerializerOptions Pretty = new() { WriteIndented = true };
    public string SchemaPath { get; private set; }
    public const string Version = "1.1.2";
    private byte[]? originalHash;
    public JsonObject Root { get; private set; } = new() { ["services"] = new JsonObject() };
    public JsonObject Services => (JsonObject)Root["services"]!;
    public string? FilePath { get; private set; }
    public bool Dirty { get; private set; }

    public ServiceDocument(string? schemaPath = null)
    {
        SchemaPath = Path.GetFullPath(schemaPath ?? Path.Combine(AppContext.BaseDirectory, "services.schema.json"));
    }

    public void SetSchema(string path)
    {
        // Keep the current selection if the replacement schema cannot be read.
        ReadSchema(Path.GetFullPath(path));
        SchemaPath = Path.GetFullPath(path);
    }

    private static (JsonSchema Schema, JsonObject Definition) ReadSchema(string path)
    {
        try
        {
            string text = File.ReadAllText(path);
            var definition = ParseUnique(text) as JsonObject
                ?? throw new InvalidDataException("Das Schema muss ein JSON-Objekt sein.");
            var meta = MetaSchemas.Draft202012.Evaluate(definition);
            if (!meta.IsValid) throw new InvalidDataException("Das Schema entspricht nicht JSON Schema Draft 2020-12.");
            return (JsonSchema.FromText(text), definition);
        }
        catch (Exception ex) when (ex is not OutOfMemoryException)
        {
            throw new InvalidDataException($"Schema konnte nicht geladen werden: {path}\n{ex.Message}", ex);
        }
    }

    public JsonObject Describe(string scope)
    {
        var root = ReadSchema(SchemaPath).Definition;
        JsonNode? node = root;
        string[] path = scope switch
        {
            "services" => ["properties", "services"],
            "groups" => ["properties", "services", "additionalProperties", "properties", "portgroups"],
            "service" => ["properties", "services", "additionalProperties"],
            "group" => ["properties", "services", "additionalProperties", "properties", "portgroups", "additionalProperties"],
            "member" => ["properties", "services", "additionalProperties", "properties", "portgroups", "additionalProperties", "properties", "members", "items"],
            _ => []
        };
        JsonNode? Resolve(JsonNode? value)
        {
            var seen = new HashSet<string>();
            while (value is JsonObject obj && obj["$ref"] is JsonValue reference && reference.TryGetValue<string>(out var pointer))
            {
                if (!pointer.StartsWith("#/", StringComparison.Ordinal) || !seen.Add(pointer)) return value;
                value = root;
                foreach (var part in pointer[2..].Split('/'))
                    value = (value as JsonObject)?[part.Replace("~1", "/").Replace("~0", "~")];
            }
            return value;
        }
        foreach (var part in path) node = (Resolve(node) as JsonObject)?[part];
        var result = Resolve(node) as JsonObject;
        if (result is null) return new JsonObject();
        var copy = (JsonObject)result.DeepClone();
        if (copy["properties"] is JsonObject properties)
            foreach (var (key, value) in properties.ToArray()) properties[key] = Resolve(value)?.DeepClone();
        return copy;
    }

    public static JsonNode? ParseUnique(string text)
    {
        using var parsed = JsonDocument.Parse(text);
        CheckDuplicateKeys(parsed.RootElement, "$");
        return JsonNode.Parse(text);
    }

    public void ReplaceJson(string text)
    {
        var root = ParseUnique(text) as JsonObject
            ?? throw new InvalidDataException("Die JSON-Wurzel muss ein Objekt sein.");
        CheckStructure(root);
        Root = root;
        Changed();
    }

    public void Changed() => Dirty = true;
    public string Json => Root.ToJsonString(Pretty) + Environment.NewLine;

    public void Load(string path)
    {
        byte[] bytes = File.ReadAllBytes(path);
        var root = ParseUnique(Encoding.UTF8.GetString(bytes).TrimStart('\uFEFF')) as JsonObject
            ?? throw new InvalidDataException("Die JSON-Wurzel muss ein Objekt sein.");
        CheckStructure(root);
        Root = root;
        FilePath = Path.GetFullPath(path);
        originalHash = SHA256.HashData(bytes);
        Dirty = false;
    }

    private static void CheckStructure(JsonObject root)
    {
        if (root["services"] is not JsonObject services)
            throw new InvalidDataException("'services' muss ein Objekt sein.");
        foreach (var (name, value) in services)
        {
            if (value is not JsonObject service) throw new InvalidDataException($"Service {name}: Objekt erwartet.");
            if (service["portgroups"] is null) continue;
            if (service["portgroups"] is not JsonObject groups) throw new InvalidDataException($"Service {name}: portgroups muss ein Objekt sein.");
            foreach (var (groupName, groupValue) in groups)
            {
                if (groupValue is not JsonObject group) throw new InvalidDataException($"{name}/{groupName}: Objekt erwartet.");
                if (group["ports"] is not null && group["ports"] is not JsonArray)
                    throw new InvalidDataException($"{name}/{groupName}: ports muss eine Liste sein.");
                if (group["members"] is null) continue;
                if (group["members"] is not JsonArray members) throw new InvalidDataException($"{name}/{groupName}: members muss eine Liste sein.");
                foreach (var member in members)
                {
                    if (member is not JsonObject m) throw new InvalidDataException($"{name}/{groupName}: Server muss ein Objekt sein.");
                }
            }
        }
    }

    private static void CheckDuplicateKeys(JsonElement element, string path)
    {
        if (element.ValueKind == JsonValueKind.Object)
        {
            var names = new HashSet<string>(StringComparer.Ordinal);
            foreach (var property in element.EnumerateObject())
            {
                if (!names.Add(property.Name)) throw new InvalidDataException($"Doppelter JSON-Schlüssel: {path}/{property.Name}");
                CheckDuplicateKeys(property.Value, path + "/" + property.Name);
            }
        }
        else if (element.ValueKind == JsonValueKind.Array)
        {
            int index = 0;
            foreach (var item in element.EnumerateArray()) CheckDuplicateKeys(item, path + "/" + index++);
        }
    }

    public IReadOnlyList<string> Validate()
    {
        var schema = ReadSchema(SchemaPath).Schema;
        var result = schema.Evaluate(Root, new EvaluationOptions
        {
            OutputFormat = OutputFormat.Hierarchical,
            RequireFormatValidation = true
        });
        var errors = new List<string>();
        Collect(result, errors);
        return errors.Distinct().ToArray();
    }

    private static void Collect(EvaluationResults result, List<string> errors)
    {
        if (result.Errors is not null)
            foreach (var error in result.Errors)
                errors.Add($"{(result.InstanceLocation.ToString() is "" ? "/" : result.InstanceLocation)} [{error.Key}]: {error.Value}");
        if (result.Details is not null)
            foreach (var child in result.Details) Collect(child, errors);
    }

    public void CheckName(string scope, string name)
    {
        if (string.IsNullOrWhiteSpace(name)) throw new InvalidDataException("Der Name darf nicht leer sein.");
        var definition = Describe(scope);
        if (definition["propertyNames"] is JsonNode nameRules)
        {
            var rule = nameRules.DeepClone();
            if (rule is JsonObject obj)
            {
                var root = ReadSchema(SchemaPath).Definition;
                if (root["$defs"] is JsonNode defs) obj["$defs"] = defs.DeepClone();
            }
            if (!JsonSchema.FromText(rule.ToJsonString()).Evaluate(JsonValue.Create(name)).IsValid)
                throw new InvalidDataException("Der Name entspricht nicht den propertyNames-Regeln des aktuellen Schemas.");
        }
    }

    public void Rename(string oldName, string newName)
    {
        if (oldName == newName) return;
        CheckName("services", newName);
        if (Services.ContainsKey(newName)) throw new InvalidDataException("Dieser Service-Name ist bereits vorhanden.");
        var value = Services[oldName] ?? throw new InvalidDataException("Service nicht gefunden.");
        Services.Remove(oldName);
        Services.Add(newName, value);
        Changed();
    }

    public void Save(string path)
    {
        var errors = Validate();
        if (errors.Count != 0) throw new InvalidDataException("Speichern abgelehnt: Schemafehler vorhanden.\n" + string.Join("\n", errors));
        path = Path.GetFullPath(path);
        if (string.Equals(path, SchemaPath, OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal))
            throw new IOException("Die Schema-Datei darf nicht mit Servicedaten überschrieben werden.");
        if (string.Equals(path, FilePath, OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal) && originalHash is not null &&
            (!File.Exists(path) || !SHA256.HashData(File.ReadAllBytes(path)).SequenceEqual(originalHash)))
            throw new IOException("Die Datei wurde außerhalb des Editors geändert oder gelöscht. Bitte unter anderem Namen speichern oder neu öffnen.");
        byte[] bytes = Encoding.UTF8.GetBytes(Json);
        string temp = Path.Combine(Path.GetDirectoryName(path)!, ".services-" + Guid.NewGuid() + ".tmp");
        try
        {
            File.WriteAllBytes(temp, bytes);
            if (File.Exists(path)) File.Copy(path, path + "." + DateTime.Now.ToString("yyyyMMdd-HHmmss-fffffff") + ".bak", false);
            File.Move(temp, path, true);
            FilePath = path;
            originalHash = SHA256.HashData(bytes);
            Dirty = false;
        }
        finally { if (File.Exists(temp)) File.Delete(temp); }
    }

    public static JsonObject NewService() => new()
    {
        ["task"] = "add", ["environment"] = "e2p", ["stage"] = "prod",
        ["cs_vip_mz"] = "", ["cs_vip_wi"] = "",
        ["portgroups"] = new JsonObject { ["portgroup001"] = NewGroup() }
    };
    public static JsonObject NewGroup() => new()
    {
        ["ports"] = new JsonArray(443),
        ["members"] = new JsonArray(NewMember())
    };
    public static JsonObject NewMember() => new() { ["server_name"] = "", ["server_ip"] = "" };
}
