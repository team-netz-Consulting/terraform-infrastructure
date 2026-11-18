using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Json.Schema;

namespace ServicesEditor;

public sealed class ServiceDocument
{
    private static readonly JsonSerializerOptions Pretty = new() { WriteIndented = true };
    private readonly JsonSchema schema;
    private byte[]? originalHash;
    public JsonObject Root { get; private set; } = new() { ["services"] = new JsonObject() };
    public JsonObject Services => (JsonObject)Root["services"]!;
    public string? FilePath { get; private set; }
    public bool Dirty { get; private set; }

    public ServiceDocument()
    {
        using var stream = typeof(ServiceDocument).Assembly.GetManifestResourceStream("services.schema.json")!;
        using var reader = new StreamReader(stream);
        schema = JsonSchema.FromText(reader.ReadToEnd());
    }

    public void Changed() => Dirty = true;
    public string Json => Root.ToJsonString(Pretty) + Environment.NewLine;

    public void Load(string path)
    {
        byte[] bytes = File.ReadAllBytes(path);
        using var parsed = JsonDocument.Parse(bytes);
        CheckDuplicateKeys(parsed.RootElement, "$");
        var root = JsonNode.Parse(bytes) as JsonObject
            ?? throw new InvalidDataException("Die JSON-Wurzel muss ein Objekt sein.");
        // Refuse structures the form cannot represent; never silently discard data.
        if (root["services"] is not JsonObject services)
            throw new InvalidDataException("'services' muss ein Objekt sein.");
        foreach (var (name, value) in services)
        {
            if (value is not JsonObject service) throw new InvalidDataException($"Service {name}: Objekt erwartet.");
            foreach (var field in new[] { "task", "servicetype", "fqdn", "environment", "stage", "cs_vip_mz", "cs_vip_wi" })
                if (service[field] is JsonNode fieldValue && (fieldValue is not JsonValue v || !v.TryGetValue<string>(out _)))
                    throw new InvalidDataException($"Service {name}: {field} muss Text sein.");
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
                    foreach (var field in new[] { "server_name", "server_ip" })
                        if (m[field] is JsonNode fv && (fv is not JsonValue v || !v.TryGetValue<string>(out _)))
                            throw new InvalidDataException($"{name}/{groupName}: {field} muss Text sein.");
                }
            }
        }
        Root = root;
        FilePath = Path.GetFullPath(path);
        originalHash = SHA256.HashData(bytes);
        Dirty = false;
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

    public void Rename(string oldName, string newName)
    {
        if (oldName == newName) return;
        if (!System.Text.RegularExpressions.Regex.IsMatch(newName, "^[A-Za-z][A-Za-z0-9_-]*$"))
            throw new InvalidDataException("Name: mit Buchstabe beginnen; nur Buchstaben, Ziffern, _ und - verwenden.");
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
