using System.Globalization;
using System.Text.Json.Nodes;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Controls.Templates;
using Avalonia.Layout;
using Avalonia.Platform.Storage;

namespace ServicesEditor;

public sealed class MainWindow : Window
{
    private ServiceDocument document = new();
    private readonly ListBox list = new();
    private readonly TextBox search = new() { PlaceholderText = "Services suchen …" };
    private readonly StackPanel details = new() { Spacing = 12, Margin = new Thickness(12) };
    private readonly TextBox errors = new() { IsReadOnly = true, AcceptsReturn = true, TextWrapping = Avalonia.Media.TextWrapping.Wrap };
    private readonly TextBox preview = new() { IsReadOnly = true, AcceptsReturn = true, FontFamily = new Avalonia.Media.FontFamily("monospace") };
    private readonly TextBlock status = new();
    private readonly Dictionary<string, TextBlock> summaryLabels = new();
    private string? selected;
    private bool refreshing;
    private bool mayClose;
    private bool confirmingClose;

    public MainWindow()
    {
        Title = "Services JSON Editor 1.0.0";
        Width = 1250; Height = 900; MinWidth = 900; MinHeight = 650;
        var root = new Grid { RowDefinitions = new RowDefinitions("Auto,*,6,220,Auto"), Margin = new Thickness(12) };
        var toolbar = Row(
            Button("Neu", async () => { if (await MayDiscard()) { document = new(); RefreshList(); Validate(); } }),
            Button("Öffnen …", Open), Button("Speichern", () => Save(false)),
            Button("Speichern unter …", () => Save(true)), Button("Prüfen", () => { Validate(); return Task.CompletedTask; }));
        toolbar.Margin = new Thickness(0, 0, 0, 12);
        root.Children.Add(toolbar);
        var body = new Grid { ColumnDefinitions = new ColumnDefinitions("310,6,*") };
        Grid.SetRow(body, 1); root.Children.Add(body);
        var sidebar = new Grid { RowDefinitions = new RowDefinitions("Auto,*,Auto") };
        sidebar.Children.Add(search);
        Grid.SetRow(list, 1); sidebar.Children.Add(list);
        list.Margin = new Thickness(0, 8);
        list.ItemTemplate = new FuncDataTemplate<string>((name, _) =>
        {
            if (name is null) return new TextBlock();
            var service = document.Services[name] as JsonObject;
            var summary = new TextBlock { Text = $"{service?["environment"]} / {service?["stage"]}", FontSize = 12 };
            summaryLabels[name] = summary;
            return new StackPanel { Children =
            {
                new TextBlock { Text = name, FontWeight = Avalonia.Media.FontWeight.SemiBold },
                summary
            }};
        });
        var actions = Row(Button("+ Service", AddService), Button("Duplizieren", DuplicateService), Button("Löschen", DeleteService));
        Grid.SetRow(actions, 2); sidebar.Children.Add(actions);
        body.Children.Add(sidebar);
        var divider = new GridSplitter { HorizontalAlignment = HorizontalAlignment.Stretch };
        Grid.SetColumn(divider, 1); body.Children.Add(divider);
        var scroll = new ScrollViewer { Content = details, HorizontalScrollBarVisibility = Avalonia.Controls.Primitives.ScrollBarVisibility.Disabled };
        Grid.SetColumn(scroll, 2); body.Children.Add(scroll);
        var horizontal = new GridSplitter { HorizontalAlignment = HorizontalAlignment.Stretch, VerticalAlignment = VerticalAlignment.Stretch };
        Grid.SetRow(horizontal, 2); root.Children.Add(horizontal);
        var tabs = new TabControl { ItemsSource = new[]
        {
            new TabItem { Header = "Schema-Prüfung", Content = errors },
            new TabItem { Header = "JSON-Vorschau", Content = preview }
        }};
        tabs.SelectionChanged += (_, _) => preview.Text = document.Json;
        Grid.SetRow(tabs, 3); root.Children.Add(tabs);
        status.Margin = new Thickness(0, 8, 0, 0);
        Grid.SetRow(status, 4); root.Children.Add(status);
        Content = root;
        search.TextChanged += (_, _) => RefreshList(selected);
        list.SelectionChanged += (_, _) =>
        {
            if (refreshing) return;
            selected = list.SelectedItem as string;
            RenderDetails(); preview.Text = document.Json;
        };
        Closing += async (_, e) =>
        {
            if (mayClose || !document.Dirty) return;
            e.Cancel = true;
            if (confirmingClose) return;
            confirmingClose = true;
            try { if (await MayDiscard()) { mayClose = true; Close(); } }
            finally { confirmingClose = false; }
        };
        RefreshList(); Validate();
    }

    private static StackPanel Row(params Control[] controls)
    {
        var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
        foreach (var control in controls) row.Children.Add(control);
        return row;
    }

    private Button Button(string title, Func<Task> action)
    {
        var button = new Button { Content = title };
        button.Click += async (_, _) =>
        {
            button.IsEnabled = false;
            try { await action(); }
            catch (Exception ex) { await Message("Aktion fehlgeschlagen", ex.Message); }
            finally { button.IsEnabled = true; }
        };
        return button;
    }

    private void Changed()
    {
        document.Changed();
        preview.Text = document.Json;
        foreach (var (name, label) in summaryLabels)
            if (document.Services[name] is JsonObject service)
                label.Text = $"{service["environment"]} / {service["stage"]}";
        errors.Text = "Änderungen noch nicht geprüft. Vor dem Speichern wird das gesamte Dokument geprüft.";
        UpdateStatus();
    }
    private void UpdateStatus()
    {
        Title = $"{(document.Dirty ? "* " : "")}{Path.GetFileName(document.FilePath) ?? "Neues Dokument"} – Services JSON Editor 1.0.0";
        status.Text = $"{document.FilePath ?? "Noch nicht gespeichert"}  |  {document.Services.Count} Services{(document.Dirty ? "  |  Ungespeicherte Änderungen" : "")}";
    }
    private void Validate()
    {
        var issues = document.Validate();
        errors.Text = issues.Count == 0 ? "✓ Das Dokument entspricht dem Schema (einschließlich IPv4-Prüfung)." :
            $"{issues.Count} Schemafehler:\n\n" + string.Join("\n", issues);
        preview.Text = document.Json;
        UpdateStatus();
    }
    private void RefreshList(string? choose = null)
    {
        refreshing = true;
        summaryLabels.Clear();
        var names = document.Services.Select(p => p.Key)
            .Where(n => n.Contains(search.Text ?? "", StringComparison.OrdinalIgnoreCase))
            .OrderBy(n => n, StringComparer.Ordinal).ToArray();
        list.ItemsSource = names;
        selected = names.Contains(choose) ? choose : names.FirstOrDefault();
        list.SelectedItem = selected;
        refreshing = false;
        RenderDetails(); UpdateStatus();
    }
    private void SelectService(string name)
    {
        search.Text = "";
        RefreshList(name);
    }

    private void TextField(StackPanel panel, JsonObject owner, string key, string label, bool optional = false)
    {
        var text = new TextBox { Name = key, Text = owner[key]?.GetValue<string>() ?? "", PlaceholderText = optional ? "Optional" : "Pflichtfeld" };
        panel.Children.Add(new TextBlock { Text = label }); panel.Children.Add(text);
        text.TextChanged += (_, _) =>
        {
            if (optional && string.IsNullOrEmpty(text.Text)) owner.Remove(key);
            else owner[key] = text.Text ?? "";
            Changed();
        };
    }
    private void Choice(StackPanel panel, JsonObject owner, string key, string label, string[] choices, bool optional = false)
    {
        string value = owner[key]?.GetValue<string>() ?? "";
        var all = choices.Concat(new[] { value }).Distinct().ToArray();
        var combo = new ComboBox { Name = key, ItemsSource = all, SelectedItem = value, HorizontalAlignment = HorizontalAlignment.Stretch };
        panel.Children.Add(new TextBlock { Text = label }); panel.Children.Add(combo);
        combo.SelectionChanged += (_, _) =>
        {
            var choice = combo.SelectedItem as string ?? "";
            if (optional && choice == "") owner.Remove(key); else owner[key] = choice;
            Changed();
        };
    }
    private void RenderDetails()
    {
        details.Children.Clear();
        if (selected is null || document.Services[selected] is not JsonObject service)
        {
            details.Children.Add(new TextBlock { Text = "JSON-Datei öffnen oder einen Service hinzufügen." }); return;
        }
        var serviceName = selected;
        details.Children.Add(Row(new TextBlock { Text = serviceName, FontSize = 22 }, Button("Umbenennen", async () =>
        {
            var name = await Prompt("Service umbenennen", serviceName);
            if (name is null) return;
            document.Rename(serviceName, name); SelectService(name); Changed();
        })));
        var general = new StackPanel { Spacing = 6 };
        Choice(general, service, "task", "Auftrag (task)", new[] { "", "add", "modify", "delete" }, true);
        general.Children.Add(new TextBlock { Text = "task=delete bleibt ein Auftrag in der Datei. „Löschen“ entfernt den Eintrag aus der Datei.", TextWrapping = Avalonia.Media.TextWrapping.Wrap, FontSize = 12 });
        TextField(general, service, "servicetype", "Service-Typ", true);
        TextField(general, service, "fqdn", "FQDN", true);
        Choice(general, service, "environment", "Environment", new[] { "e2a", "e2p", "e2t", "etl" });
        Choice(general, service, "stage", "Stage", new[] { "eng", "kt", "at", "prod" });
        TextField(general, service, "cs_vip_mz", "CS-VIP MZ (IPv4)");
        TextField(general, service, "cs_vip_wi", "CS-VIP WI (IPv4)");
        details.Children.Add(general);
        details.Children.Add(Button("+ Portgruppe", async () =>
        {
            var name = await Prompt("Portgruppe hinzufügen", NextGroup(service["portgroups"] as JsonObject));
            if (name is null) return;
            CheckGroupName(name);
            var groups = service["portgroups"] as JsonObject ?? new JsonObject();
            if (groups.ContainsKey(name)) throw new InvalidDataException("Portgruppe bereits vorhanden.");
            if (service["portgroups"] is null) service["portgroups"] = groups;
            groups.Add(name, ServiceDocument.NewGroup()); Changed(); RenderDetails();
        }));
        if (service["portgroups"] is not JsonObject portgroups) return;
        foreach (var (groupName, node) in portgroups.ToArray())
        {
            var group = (JsonObject)node!;
            var panel = new StackPanel { Spacing = 8, Margin = new Thickness(8) };
            panel.Children.Add(Row(Button("Umbenennen", async () =>
            {
                var name = await Prompt("Portgruppe umbenennen", groupName);
                if (name is null || name == groupName) return;
                CheckGroupName(name);
                if (portgroups.ContainsKey(name)) throw new InvalidDataException("Portgruppe bereits vorhanden.");
                portgroups.Remove(groupName); portgroups.Add(name, group); Changed(); RenderDetails();
            }), Button("Portgruppe löschen", async () =>
            {
                if (await Confirm("Portgruppe löschen", $"{groupName} mit allen Servern aus der Datei entfernen?"))
                { portgroups.Remove(groupName); Changed(); RenderDetails(); }
            })));
            var ports = new TextBox { Name = "ports", PlaceholderText = "443, 8443", Text = group["ports"] is JsonArray array ? string.Join(", ", array.Select(p => p is JsonValue v && v.TryGetValue<string>(out var s) ? s : p?.ToJsonString() ?? "null")) : "" };
            panel.Children.Add(new TextBlock { Text = "Ports (durch Komma getrennt, 1–65535)" }); panel.Children.Add(ports);
            ports.TextChanged += (_, _) =>
            {
                var values = new JsonArray();
                foreach (var token in (ports.Text ?? "").Split(',', StringSplitOptions.TrimEntries))
                {
                    if (string.IsNullOrWhiteSpace(ports.Text)) break;
                    values.Add(int.TryParse(token, NumberStyles.None, CultureInfo.InvariantCulture, out int number) ? JsonValue.Create(number) : JsonValue.Create(token));
                }
                group["ports"] = values; Changed();
            };
            panel.Children.Add(new TextBlock { Text = "Server / Mitglieder", FontWeight = Avalonia.Media.FontWeight.SemiBold });
            if (group["members"] is JsonArray members)
                foreach (var memberNode in members.ToArray())
                {
                    var member = (JsonObject)memberNode!;
                    var fields = new StackPanel { Spacing = 4 };
                    TextField(fields, member, "server_name", "Servername");
                    TextField(fields, member, "server_ip", "IPv4-Adresse");
                    fields.Children.Add(Button("Server entfernen", async () =>
                    {
                        if (await Confirm("Server entfernen", $"Server {member["server_name"]} aus {groupName} entfernen?"))
                        { members.Remove(member); Changed(); RenderDetails(); }
                    }));
                    panel.Children.Add(new Border { Child = fields, Padding = new Thickness(8), BorderThickness = new Thickness(1), BorderBrush = Avalonia.Media.Brushes.Gray, CornerRadius = new CornerRadius(4) });
                }
            panel.Children.Add(Button("+ Server", () =>
            {
                if (group["members"] is not JsonArray) group["members"] = new JsonArray();
                ((JsonArray)group["members"]!).Add(ServiceDocument.NewMember()); Changed(); RenderDetails(); return Task.CompletedTask;
            }));
            details.Children.Add(new Expander { Header = groupName, Content = panel, IsExpanded = true, HorizontalAlignment = HorizontalAlignment.Stretch });
        }
    }
    private static string NextGroup(JsonObject? groups)
    {
        int i = 1; while (groups?.ContainsKey($"portgroup{i:000}") == true) i++;
        return $"portgroup{i:000}";
    }
    private static void CheckGroupName(string name)
    {
        if (!System.Text.RegularExpressions.Regex.IsMatch(name, "^portgroup[0-9]+$"))
            throw new InvalidDataException("Portgruppenname muss 'portgroup' gefolgt von Ziffern sein.");
    }
    private async Task AddService()
    {
        var name = await Prompt("Service hinzufügen", "service-neu");
        if (name is null) return;
        if (!System.Text.RegularExpressions.Regex.IsMatch(name, "^[A-Za-z][A-Za-z0-9_-]*$")) throw new InvalidDataException("Ungültiger Service-Name.");
        if (document.Services.ContainsKey(name)) throw new InvalidDataException("Service bereits vorhanden.");
        document.Services.Add(name, ServiceDocument.NewService()); Changed(); SelectService(name);
    }
    private async Task DuplicateService()
    {
        if (selected is null) return;
        var source = selected;
        var name = await Prompt("Service duplizieren", source + "-kopie");
        if (name is null) return;
        if (!System.Text.RegularExpressions.Regex.IsMatch(name, "^[A-Za-z][A-Za-z0-9_-]*$")) throw new InvalidDataException("Ungültiger Service-Name.");
        if (document.Services.ContainsKey(name)) throw new InvalidDataException("Service bereits vorhanden.");
        document.Services.Add(name, document.Services[source]!.DeepClone()); Changed(); SelectService(name);
    }
    private async Task DeleteService()
    {
        if (selected is null) return;
        var name = selected;
        if (await Confirm("Service löschen", $"Service {name} vollständig aus der JSON-Datei entfernen?"))
        { document.Services.Remove(name); Changed(); RefreshList(); }
    }
    private static readonly FilePickerFileType JsonType = new("JSON-Dateien") { Patterns = new[] { "*.json" } };
    private async Task Open()
    {
        var files = await StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions { Title = "Services-JSON öffnen", AllowMultiple = false, FileTypeFilter = new[] { JsonType } });
        if (files.Count == 0) return;
        if (!await MayDiscard()) return;
        var candidate = new ServiceDocument();
        candidate.Load(files[0].TryGetLocalPath() ?? throw new IOException("Bitte eine lokale Datei wählen."));
        document = candidate; search.Text = ""; RefreshList(); Validate();
    }
    private async Task<bool> Save(bool saveAs)
    {
        Validate();
        if (document.Validate().Count != 0) { await Message("Schemafehler", "Bitte zuerst die Fehler im Bereich Schema-Prüfung beheben. Die Datei wurde nicht gespeichert."); return false; }
        string? path = document.FilePath;
        if (saveAs || path is null)
        {
            var file = await StorageProvider.SaveFilePickerAsync(new FilePickerSaveOptions { Title = "Services-JSON speichern", SuggestedFileName = path is null ? "services.json" : Path.GetFileName(path), DefaultExtension = "json", FileTypeChoices = new[] { JsonType }, ShowOverwritePrompt = true });
            if (file is null) return false;
            path = file.TryGetLocalPath() ?? throw new IOException("Bitte eine lokale Datei wählen.");
        }
        document.Save(path); Validate(); return true;
    }
    private async Task<bool> MayDiscard()
    {
        if (!document.Dirty) return true;
        string? answer = await Dialog("Ungespeicherte Änderungen", "Änderungen vor dem Fortfahren speichern?", null, new[] { "Speichern", "Verwerfen", "Abbrechen" });
        if (answer == "Verwerfen") return true;
        if (answer != "Speichern") return false;
        try { return await Save(false); }
        catch (Exception ex) { await Message("Speichern fehlgeschlagen", ex.Message); return false; }
    }
    private async Task<string?> Prompt(string title, string initial)
    {
        var input = new TextBox { Text = initial };
        var result = await Dialog(title, "Name:", input, new[] { "Übernehmen", "Abbrechen" });
        return result == "Übernehmen" ? input.Text?.Trim() ?? "" : null;
    }
    private async Task<bool> Confirm(string title, string text) => await Dialog(title, text, null, new[] { "Ja", "Abbrechen" }) == "Ja";
    private async Task Message(string title, string text) => await Dialog(title, text, null, new[] { "OK" });
    private async Task<string?> Dialog(string title, string text, Control? input, string[] answers)
    {
        var window = new Window { Title = title, Width = 570, SizeToContent = SizeToContent.Height, CanResize = false, WindowStartupLocation = WindowStartupLocation.CenterOwner };
        var panel = new StackPanel { Spacing = 14, Margin = new Thickness(20) };
        panel.Children.Add(new TextBlock { Text = text, TextWrapping = Avalonia.Media.TextWrapping.Wrap, MaxHeight = 350 });
        if (input is not null) panel.Children.Add(input);
        var buttons = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8, HorizontalAlignment = HorizontalAlignment.Right };
        foreach (var answer in answers)
        {
            var button = new Button { Content = answer };
            button.Click += (_, _) => window.Close(answer);
            buttons.Children.Add(button);
        }
        panel.Children.Add(buttons); window.Content = panel;
        if (input is TextBox box) window.Opened += (_, _) => { box.Focus(); box.SelectAll(); };
        return await window.ShowDialog<string?>(this);
    }
}
