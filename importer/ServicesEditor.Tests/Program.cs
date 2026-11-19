using System.Text.Json.Nodes;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Headless;
using Avalonia.Interactivity;
using Avalonia.Threading;
using Avalonia.VisualTree;
using ServicesEditor;

int passed = 0;
string directory = Path.Combine(Path.GetTempPath(), "services-editor-tests-" + Guid.NewGuid());
Directory.CreateDirectory(directory);
string example = File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "services.example.json"));
string source = Path.Combine(directory, "source.json");
File.WriteAllText(source, example);
void Test(string name, Action action)
{
    action(); passed++; Console.WriteLine("PASS " + name);
}
void Assert(bool condition, string message = "Assertion failed")
{
    if (!condition) throw new Exception(message);
}
ServiceDocument Load()
{
    File.WriteAllText(source, example);
    var document = new ServiceDocument(); document.Load(source); return document;
}
void Reject<T>(Action action) where T : Exception
{
    try { action(); } catch (T) { return; }
    throw new Exception("Expected " + typeof(T).Name);
}
try
{
    Test("Beispieldatei entspricht externem Schema", () => Assert(Load().Validate().Count == 0));
    Test("Draft 2020-12: IPv4, Pflichtfelder, Enum und unbekannte Eigenschaften", () =>
    {
        foreach (var field in new[] { "cs_vip_wi", "cs_vip_mz", "environment", "stage", "task", "unexpected" })
        {
            var d = Load(); var s = (JsonObject)d.Services.First().Value!;
            s[field] = "invalid"; Assert(d.Validate().Count > 0, field);
        }
        var required = Load(); ((JsonObject)required.Services.First().Value!).Remove("stage");
        Assert(required.Validate().Any(x => x.Contains("required")));
    });
    Test("Ports: Grenzen, Duplikate und Datentypen", () =>
    {
        foreach (var bad in new[] { "[0]", "[65536]", "[443,443]", "[\"443\"]", "[true]", "[]" })
        {
            var d = Load(); var s = (JsonObject)d.Services.First().Value!;
            s["portgroups"]!.AsObject().First().Value!["ports"] = JsonNode.Parse(bad);
            Assert(d.Validate().Count > 0, bad);
        }
    });
    Test("Service- und Portgruppennamen werden validiert", () =>
    {
        var d = Load(); d.Services["1bad"] = ServiceDocument.NewService(); Assert(d.Validate().Count > 0);
        d = Load(); var groups = d.Services.First().Value!["portgroups"]!.AsObject();
        groups["wrong"] = ServiceDocument.NewGroup(); Assert(d.Validate().Count > 0);
    });
    Test("Umbenennen und Duplizieren erhalten verschachtelte Daten", () =>
    {
        var d = Load(); string oldName = d.Services.First().Key;
        var copy = d.Services[oldName]!.DeepClone();
        d.Rename(oldName, "renamed");
        Assert(d.Dirty && !d.Services.ContainsKey(oldName));
        Assert(JsonNode.DeepEquals(copy, d.Services["renamed"]));
        d.Services.Add("copy", copy);
        Reject<InvalidDataException>(() => d.Rename("renamed", "copy"));
        Reject<InvalidDataException>(() => d.Rename("renamed", "bad name"));
        d.Services["copy"]!["stage"] = "kt";
        Assert(d.Services["renamed"]!["stage"]!.GetValue<string>() != "kt");
    });
    Test("Speichern erzeugt Sicherung und erhält alle JSON-Werte", () =>
    {
        var d = Load(); d.Services.First().Value!["stage"] = "kt"; d.Changed(); d.Save(source);
        Assert(!d.Dirty);
        Assert(File.ReadAllText(Directory.GetFiles(directory, "source.json.*.bak").Single()) == example);
        var reopened = new ServiceDocument(); reopened.Load(source);
        Assert(JsonNode.DeepEquals(d.Root, reopened.Root));
    });
    Test("Ungültige Dokumente überschreiben keine Datei", () =>
    {
        var d = Load(); d.Services.Clear();
        Reject<InvalidDataException>(() => d.Save(source)); Assert(File.ReadAllText(source) == example);
    });
    Test("Externe Änderungen und gelöschte Dateien bleiben geschützt", () =>
    {
        var d = Load(); File.WriteAllText(source, "external");
        Reject<IOException>(() => d.Save(source)); Assert(File.ReadAllText(source) == "external");
        File.Delete(source); Reject<IOException>(() => d.Save(source));
        d.Save(Path.Combine(directory, "save-as.json"));
    });
    Test("Doppelte Schlüssel und unlesbare Strukturen lassen Dokument unverändert", () =>
    {
        var d = Load(); string before = d.Json;
        foreach (string bad in new[] { "{\"services\":{},\"services\":{}}", "{\"services\":{\"s\":null}}", "{\"services\":{\"s\":{\"portgroups\":1}}}", "{ broken" })
        {
            File.WriteAllText(source, bad);
            try { d.Load(source); throw new Exception("Bad file accepted"); }
            catch (Exception ex) when (ex is InvalidDataException or System.Text.Json.JsonException) { }
            Assert(d.Json == before);
        }
    });
    Test("Unbekannte Eigenschaften werden erhalten und als Fehler angezeigt", () =>
    {
        var d = Load(); d.Root["unknown"] = new JsonObject { ["secret"] = "retained" };
        File.WriteAllText(source, d.Json); d.Load(source);
        Assert(d.Root["unknown"]!["secret"]!.GetValue<string>() == "retained");
        Assert(d.Validate().Count > 0);
    });
    Test("Externes Schema wird ohne Neustart neu gelesen und Erweiterungen werden gespeichert", () =>
    {
        string schemaPath = Path.Combine(directory, "custom.schema.json");
        string originalSchema = File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "services.schema.json"));
        File.WriteAllText(schemaPath, originalSchema);
        var d = Load(); d.SetSchema(schemaPath); Assert(d.Validate().Count == 0);
        var schema = JsonNode.Parse(originalSchema)!;
        var service = schema["$defs"]!["service"]!;
        service["properties"]!["priority"] = JsonNode.Parse("{\"type\":\"integer\",\"minimum\":1}");
        service["required"]!.AsArray().Add("priority");
        service["properties"]!["stage"]!["enum"]!.AsArray().Add("preview");
        File.WriteAllText(schemaPath, schema.ToJsonString());
        Assert(d.Validate().Count > 0);
        foreach (var (_, value) in d.Services) { value!["priority"] = 2; value["stage"] = "preview"; }
        Assert(d.Validate().Count == 0);
        d.Save(Path.Combine(directory, "extended.json"));
        var reopened = new ServiceDocument(schemaPath); reopened.Load(Path.Combine(directory, "extended.json"));
        Assert(reopened.Validate().Count == 0 && reopened.Services.First().Value!["priority"]!.GetValue<int>() == 2);
        Assert(d.Describe("service")["properties"]!["cs_vip_wi"]!["format"]!.ToString() == "ipv4");
        Reject<IOException>(() => d.Save(schemaPath));
    });
    Test("Fehlende und defekte Schemata blockieren das Speichern ohne Fallback", () =>
    {
        var d = Load(); string before = File.ReadAllText(source);
        var schemaPath = Path.Combine(directory, "broken.schema.json");
        File.Copy(Path.Combine(AppContext.BaseDirectory, "services.schema.json"), schemaPath);
        d.SetSchema(schemaPath);
        foreach (var text in new[] { "{broken", "{\"type\":42}", "{\"type\":\"object\",\"type\":\"string\"}" })
        {
            File.WriteAllText(schemaPath, text);
            Reject<InvalidDataException>(() => d.Validate());
            Reject<InvalidDataException>(() => d.Save(source));
            Assert(File.ReadAllText(source) == before);
        }
        File.Delete(schemaPath);
        Reject<InvalidDataException>(() => d.Validate());
        Reject<InvalidDataException>(() => d.Save(source));
        string oldPath = d.SchemaPath;
        Reject<InvalidDataException>(() => d.SetSchema(Path.Combine(directory, "not-found.json")));
        Assert(d.SchemaPath == oldPath);
    });
    Test("JSON-Bearbeitung erhält Schema und Dateibezug; Syntaxfehler verändern nichts", () =>
    {
        var d = Load(); string path = d.FilePath!, schemaPath = d.SchemaPath, before = d.Json;
        Reject<System.Text.Json.JsonException>(() => d.ReplaceJson("{broken")); Assert(d.Json == before);
        Reject<InvalidDataException>(() => d.ReplaceJson("{\"services\":{},\"services\":{}}")); Assert(d.Json == before);
        var root = JsonNode.Parse(before)!; root["metadata"] = JsonNode.Parse("{\"owner\":\"test\"}");
        d.ReplaceJson(root.ToJsonString());
        Assert(d.Dirty && d.FilePath == path && d.SchemaPath == schemaPath);
        Assert(d.Root["metadata"]!["owner"]!.ToString() == "test");
    });
    Test("Appsettings: Erstanlage, letzter Schema-Pfad und unbekannte Einstellungen", () =>
    {
        string folder = Path.Combine(directory, "settings"); Directory.CreateDirectory(folder);
        string settingsPath = Path.Combine(folder, "appsettings.json");
        File.Copy(Path.Combine(AppContext.BaseDirectory, "services.schema.json"), Path.Combine(folder, "services.schema.json"));
        var settings = new AppSettingsStore(settingsPath);
        var initial = settings.Load();
        Assert(File.Exists(settingsPath) && initial.Notice?.Contains("angelegt") == true);
        Assert(initial.SchemaPath == Path.Combine(folder, "services.schema.json"));
        string custom = Path.Combine(folder, "custom.schema.json"); File.Copy(initial.SchemaPath, custom);
        File.WriteAllText(settingsPath, "{\"OtherSetting\":42}");
        settings.SaveSchema(custom);
        var restarted = new AppSettingsStore(settingsPath).Load();
        Assert(restarted.SchemaPath == custom && restarted.Notice is null);
        Assert(JsonNode.Parse(File.ReadAllText(settingsPath))!["OtherSetting"]!.GetValue<int>() == 42);
        File.Delete(custom);
        var missing = settings.Load();
        Assert(missing.SchemaPath == custom && missing.Notice?.Contains("nicht gefunden") == true);
        Assert(JsonNode.Parse(File.ReadAllText(settingsPath))!["LastSchemaPath"]!.ToString() == custom);
    });
    Test("Appsettings: relative Pfade und defekte Dateien werden kontrolliert behandelt", () =>
    {
        string settingsPath = Path.Combine(directory, "invalid-appsettings.json");
        var settings = new AppSettingsStore(settingsPath);
        File.WriteAllText(settingsPath, "{\"LastSchemaPath\":\"relative.schema.json\"}");
        Assert(settings.Load().SchemaPath == Path.Combine(directory, "relative.schema.json"));
        foreach (var text in new[] { "{broken", "[]", "{\"LastSchemaPath\":\"a\",\"LastSchemaPath\":\"b\"}" })
        {
            File.WriteAllText(settingsPath, text);
            Assert(settings.Load().Notice?.Contains("konnte nicht") == true);
            Assert(File.ReadAllText(settingsPath) == text);
        }
    });
    Test("Headless-Oberfläche: Hinzufügen, Bearbeiten, Duplizieren und Löschen", () =>
    {
        AppBuilder.Configure<App>().UseHeadless(new AvaloniaHeadlessPlatformOptions()).SetupWithoutStarting();
        var window = new MainWindow(); window.Show();
        Button FindButton(Window owner, string label) => owner.GetVisualDescendants().OfType<Button>().First(b => Equals(b.Content, label));
        void Click(Window owner, string label)
        {
            FindButton(owner, label).RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            Dispatcher.UIThread.RunJobs();
        }
        Click(window, "+ Service");
        var dialog = window.OwnedWindows.Single();
        dialog.GetVisualDescendants().OfType<TextBox>().Single().Text = "my-service";
        Click(dialog, "Übernehmen");
        Assert(window.GetVisualDescendants().OfType<ListBox>().Single().ItemCount == 1);
        var fields = window.GetVisualDescendants().OfType<TextBox>().ToArray();
        fields.First(t => t.PlaceholderText?.ToString() == "Pflichtfeld").Text = "192.0.2.1";
        Click(window, "Duplizieren"); dialog = window.OwnedWindows.Single();
        Click(dialog, "Übernehmen");
        Assert(window.GetVisualDescendants().OfType<ListBox>().Single().ItemCount == 2);
        Click(window, "Löschen");
        dialog = window.OwnedWindows.Single(); Click(dialog, "Ja");
        Assert(window.GetVisualDescendants().OfType<ListBox>().Single().ItemCount == 1);
        foreach (var (key, value) in new[] { ("cs_vip_mz", "192.0.2.1"), ("cs_vip_wi", "192.0.2.2"), ("server_name", "server-01"), ("server_ip", "198.51.100.1") })
            window.GetVisualDescendants().OfType<TextBox>().Single(t => t.Name == key).Text = value;
        window.GetVisualDescendants().OfType<ComboBox>().Single(c => c.Name == "stage").SelectedItem = "kt";
        Dispatcher.UIThread.RunJobs();
        Assert(window.GetVisualDescendants().OfType<TextBlock>().Any(t => t.Text == "e2p / kt"));
        Click(window, "Prüfen");
        Assert(window.GetVisualDescendants().OfType<TextBox>().Any(t => t.IsReadOnly && t.Text?.StartsWith("✓") == true));
        Click(window, "+ Portgruppe"); dialog = window.OwnedWindows.Single(); Click(dialog, "Übernehmen");
        Assert(window.GetVisualDescendants().OfType<Expander>().Count() == 2);
        Click(window, "Portgruppe löschen"); dialog = window.OwnedWindows.Single(); Click(dialog, "Ja");
        Assert(window.GetVisualDescendants().OfType<Expander>().Count() == 1);
        window.Close(); Dispatcher.UIThread.RunJobs();
        dialog = window.OwnedWindows.Single(); Click(dialog, "Verwerfen");
    });
    Test("Headless: neue Schemafelder, neue Enumwerte und JSON-Erweiterungen", () =>
    {
        string schemaPath = Path.Combine(directory, "ui.schema.json");
        var schema = JsonNode.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "services.schema.json")))!;
        var properties = schema["$defs"]!["service"]!["properties"]!;
        properties["priority"] = JsonNode.Parse("{\"type\":\"integer\",\"minimum\":1}");
        properties["enabled"] = JsonNode.Parse("{\"type\":\"boolean\"}");
        properties["notes"] = JsonNode.Parse("{\"type\":\"string\"}");
        properties["labels"] = JsonNode.Parse("{\"type\":\"object\"}");
        properties["stage"]!["enum"]!.AsArray().Add("preview");
        schema["$defs"]!["portgroup"]!["properties"]!["timeout"] = JsonNode.Parse("{\"type\":\"integer\"}");
        schema["$defs"]!["member"]!["properties"]!["active"] = JsonNode.Parse("{\"type\":\"boolean\"}");
        File.WriteAllText(schemaPath, schema.ToJsonString());
        var window = new MainWindow(schemaPath); window.Show();
        void Click(Window owner, string label)
        {
            owner.GetVisualDescendants().OfType<Button>().First(b => Equals(b.Content, label)).RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
            Dispatcher.UIThread.RunJobs();
        }
        Click(window, "+ Service"); var dialog = window.OwnedWindows.Single(); Click(dialog, "Übernehmen");
        window.GetVisualDescendants().OfType<TextBox>().Single(t => t.Name == "priority").Text = "5";
        window.GetVisualDescendants().OfType<TextBox>().Single(t => t.Name == "notes").Text = "Neue Felder";
        window.GetVisualDescendants().OfType<TextBox>().Single(t => t.Name == "timeout").Text = "30";
        window.GetVisualDescendants().OfType<CheckBox>().Single(t => t.Name == "enabled").IsChecked = true;
        window.GetVisualDescendants().OfType<CheckBox>().Single(t => t.Name == "active").IsChecked = false;
        window.GetVisualDescendants().OfType<ComboBox>().Single(c => c.Name == "stage").SelectedItem = "preview";
        Dispatcher.UIThread.RunJobs();
        Click(window, "labels als JSON bearbeiten …"); dialog = window.OwnedWindows.Single();
        dialog.GetVisualDescendants().OfType<TextBox>().Single().Text = "{\"owner\":\"team\"}"; Click(dialog, "Übernehmen");
        window.GetVisualDescendants().OfType<TabControl>().Single().SelectedIndex = 1; Dispatcher.UIThread.RunJobs();
        var preview = window.GetVisualDescendants().OfType<TextBox>().Single(t => t.IsReadOnly && t.Text?.Contains("\"services\"") == true);
        var root = JsonNode.Parse(preview.Text!)!; var service = root["services"]!["service-neu"]!;
        Assert(service["priority"]!.GetValue<int>() == 5 && service["enabled"]!.GetValue<bool>());
        Assert(service["labels"]!["owner"]!.ToString() == "team" && service["stage"]!.ToString() == "preview");
        Assert(service["portgroups"]!["portgroup001"]!["timeout"]!.GetValue<int>() == 30);
        Assert(!service["portgroups"]!["portgroup001"]!["members"]![0]!["active"]!.GetValue<bool>());
        // The reload action preserves values and applies externally changed choices.
        properties["stage"]!["enum"]!.AsArray().Add("next-stage"); File.WriteAllText(schemaPath, schema.ToJsonString());
        Click(window, "Schema neu laden");
        Assert(window.GetVisualDescendants().OfType<ComboBox>().Single(c => c.Name == "stage").ItemsSource!.Cast<string>().Contains("next-stage"));
        Click(window, "JSON bearbeiten …"); dialog = window.OwnedWindows.Single();
        dialog.GetVisualDescendants().OfType<TextBox>().Single().Text = "{broken"; Click(dialog, "Abbrechen");
        Assert(window.OwnedWindows.Count == 0);
        Click(window, "JSON bearbeiten …"); dialog = window.OwnedWindows.Single();
        dialog.GetVisualDescendants().OfType<TextBox>().Single().Text = "{broken";
        Click(dialog, "Übernehmen"); dialog = window.OwnedWindows.Single();
        Assert(dialog.Title == "Ungültiges JSON"); Click(dialog, "OK");
        dialog = window.OwnedWindows.Single();
        Assert(dialog.GetVisualDescendants().OfType<TextBox>().Single().Text == "{broken");
        root["metadata"] = JsonNode.Parse("{\"owner\":\"root-extension\"}");
        root["services"]!["service-neu"]!["portgroups"]!["portgroup001"]!["ports"] = JsonNode.Parse("[null]");
        dialog.GetVisualDescendants().OfType<TextBox>().Single().Text = root.ToJsonString(); Click(dialog, "Übernehmen");
        Assert(window.OwnedWindows.Count == 0);
        preview = window.GetVisualDescendants().OfType<TextBox>().Single(t => t.IsReadOnly && t.Text?.Contains("\"services\"") == true);
        Assert(JsonNode.Parse(preview.Text!)!["metadata"]!["owner"]!.ToString() == "root-extension");
        Assert(JsonNode.Parse(preview.Text!)!["services"]!["service-neu"]!["portgroups"]!["portgroup001"]!["ports"]![0] is null);
        window.Close(); Dispatcher.UIThread.RunJobs(); dialog = window.OwnedWindows.Single(); Click(dialog, "Verwerfen");
    });
    Test("Headless: fehlendes gespeichertes Schema zeigt beim Start einen Hinweis", () =>
    {
        var settings = new AppSettingsStore(Path.Combine(directory, "startup-appsettings.json"));
        string missing = Path.Combine(directory, "missing-startup.schema.json");
        settings.SaveSchema(missing);
        var startup = settings.Load();
        var window = new MainWindow(startup.SchemaPath, settings, startup.Notice);
        window.Show(); Dispatcher.UIThread.RunJobs();
        var dialog = window.OwnedWindows.Single();
        Assert(dialog.Title == "Hinweis");
        Assert(dialog.GetVisualDescendants().OfType<TextBlock>().Any(t => t.Text?.Contains(missing) == true));
        dialog.GetVisualDescendants().OfType<Button>().Single(b => Equals(b.Content, "OK")).RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
        Dispatcher.UIThread.RunJobs();
        Assert(window.OwnedWindows.Count == 0);
        window.Close();
    });
    Console.WriteLine($"{passed} Prüfungen erfolgreich.");
    return 0;
}
catch (Exception ex) { Console.Error.WriteLine(ex); return 1; }
finally { Directory.Delete(directory, true); }
