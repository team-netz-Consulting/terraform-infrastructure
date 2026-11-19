using System.Text;
using System.Text.Json.Nodes;

namespace ServicesEditor;

public sealed class AppSettingsStore
{
    public string FilePath { get; }
    private string DefaultSchemaPath => Path.Combine(Path.GetDirectoryName(FilePath)!, "services.schema.json");

    public AppSettingsStore(string? path = null)
    {
        FilePath = Path.GetFullPath(path ?? Path.Combine(AppContext.BaseDirectory, "appsettings.json"));
    }

    public (string SchemaPath, string? Notice) Load()
    {
        string schemaPath = DefaultSchemaPath;
        string? notice = null;
        try
        {
            if (!File.Exists(FilePath))
            {
                SaveSchema(schemaPath);
                notice = "appsettings.json wurde mit dem Standard-Schema angelegt.";
            }
            else
            {
                var settings = Read();
                if (settings["LastSchemaPath"] is JsonValue value && value.TryGetValue<string>(out var saved) && !string.IsNullOrWhiteSpace(saved))
                    schemaPath = Path.GetFullPath(saved, Path.GetDirectoryName(FilePath)!);
                else notice = "Kein Schema-Pfad in appsettings.json gespeichert. Das Standard-Schema wird verwendet.";
            }
        }
        catch (Exception ex) when (ex is IOException or InvalidDataException or UnauthorizedAccessException or System.Text.Json.JsonException or ArgumentException)
        {
            notice = "appsettings.json konnte nicht geladen oder angelegt werden. Das Standard-Schema wird verwendet.\n" + ex.Message;
        }
        if (!File.Exists(schemaPath))
            notice = (notice is null ? "" : notice + "\n") + "Schema-Datei nicht gefunden:\n" + schemaPath + "\nBitte über „Schema wählen“ eine Datei auswählen.";
        return (schemaPath, notice);
    }

    private JsonObject Read() => ServiceDocument.ParseUnique(File.ReadAllText(FilePath)) as JsonObject
        ?? throw new InvalidDataException("appsettings.json muss ein JSON-Objekt sein.");

    public void SaveSchema(string schemaPath)
    {
        var settings = File.Exists(FilePath) ? Read() : new JsonObject();
        settings["LastSchemaPath"] = Path.GetFullPath(schemaPath);
        string temporary = Path.Combine(Path.GetDirectoryName(FilePath)!, ".appsettings-" + Guid.NewGuid() + ".tmp");
        try
        {
            File.WriteAllText(temporary, settings.ToJsonString(new() { WriteIndented = true }) + Environment.NewLine, new UTF8Encoding(false));
            File.Move(temporary, FilePath, true);
        }
        finally { if (File.Exists(temporary)) File.Delete(temporary); }
    }
}
