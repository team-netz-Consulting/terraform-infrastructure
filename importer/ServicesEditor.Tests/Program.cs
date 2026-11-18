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
    Test("Beispieldatei entspricht eingebettetem Schema", () => Assert(Load().Validate().Count == 0));
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
        foreach (string bad in new[] { "{\"services\":{},\"services\":{}}", "{\"services\":{\"s\":null}}", "{\"services\":{\"s\":{\"stage\":1}}}", "{ broken" })
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
    Console.WriteLine($"{passed} Prüfungen erfolgreich.");
    return 0;
}
catch (Exception ex) { Console.Error.WriteLine(ex); return 1; }
finally { Directory.Delete(directory, true); }
