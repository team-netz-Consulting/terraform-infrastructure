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
    private readonly AppSettingsStore? settings;
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

    public MainWindow(string? schemaPath = null, AppSettingsStore? settings = null, string? startupNotice = null)
    {
        document = new ServiceDocument(schemaPath);
        this.settings = settings;
        if (startupNotice is not null) Opened += async (_, _) => await Message("Hinweis", startupNotice);
        Title = "Services JSON Editor 1.1.2";
        Width = 1250; Height = 900; MinWidth = 900; MinHeight = 650;
        var root = new Grid { RowDefinitions = new RowDefinitions("Auto,*,6,220,Auto"), Margin = new Thickness(12) };
        var toolbar = Row(
            Button("Neu", async () => { if (await MayDiscard()) { document = new(document.SchemaPath); RefreshList(); Validate(); } }),
            Button("Öffnen …", Open), Button("Speichern", () => Save(false)),
            Button("Speichern unter …", () => Save(true)), Button("Prüfen", () => { RenderDetails(); Validate(); return Task.CompletedTask; }));
        toolbar.Margin = new Thickness(0, 0, 0, 12);
        var schemaToolbar = Row(Button("Schema wählen …", ChooseSchema),
            Button("Schema neu laden", () => { RenderDetails(); Validate(); return Task.CompletedTask; }),
            Button("JSON bearbeiten …", EditDocumentJson));
        var top = new StackPanel { Spacing = 6, Margin = new Thickness(0, 0, 0, 8) };
        top.Children.Add(toolbar); top.Children.Add(schemaToolbar);
        root.Children.Add(top);
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
            var summary = new TextBlock { Text = $"{service?["environment"]} / {service?["stage"]}", FontSize = 11 };
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
        status.TextWrapping = Avalonia.Media.TextWrapping.Wrap;
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
        Title = $"{(document.Dirty ? "* " : "")}{Path.GetFileName(document.FilePath) ?? "Neues Dokument"} – Services JSON Editor 1.1.2";
        status.Text = $"{document.FilePath ?? "Noch nicht gespeichert"}  |  {document.Services.Count} Services{(document.Dirty ? "  |  Ungespeicherte Änderungen" : "")}\nSchema: {document.SchemaPath}";
    }
    private void Validate()
    {
        try
        {
            var issues = document.Validate();
            errors.Text = issues.Count == 0 ? "✓ Das Dokument entspricht dem Schema (einschließlich IPv4-Prüfung)." :
                $"{issues.Count} Schemafehler:\n\n" + string.Join("\n", issues);
        }
        catch (Exception ex) { errors.Text = "Schema-Prüfung fehlgeschlagen. Speichern ist gesperrt.\n" + ex.Message; }
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

    private void SetField(JsonObject owner, string key, JsonNode? value, bool remove = false)
    {
        if (remove)
        {
            if (!owner.Remove(key)) return;
        }
        else
        {
            if (owner.ContainsKey(key) && JsonNode.DeepEquals(owner[key], value)) return;
            owner[key] = value;
        }
        Changed();
    }

    private void TextField(StackPanel panel, JsonObject owner, string key, string label, bool optional = false)
    {
        var text = new TextBox { Name = key, Text = owner[key]?.GetValue<string>() ?? "", PlaceholderText = optional ? "Optional" : "Pflichtfeld" };
        panel.Children.Add(new TextBlock { Text = label }); panel.Children.Add(text);
        string? previousText = text.Text;
        text.TextChanged += (_, _) =>
        {
            if (text.Text == previousText) return;
            previousText = text.Text;
            SetField(owner, key, JsonValue.Create(text.Text ?? ""), optional && string.IsNullOrEmpty(text.Text));
        };
    }
    private void Choice(StackPanel panel, JsonObject owner, string key, string label, string[] choices, bool optional = false)
    {
        string value = owner[key]?.GetValue<string>() ?? "";
        var all = choices.Concat(new[] { value }).Distinct().ToArray();
        var combo = new ComboBox { Name = key, ItemsSource = all, SelectedItem = value, HorizontalAlignment = HorizontalAlignment.Stretch };
        panel.Children.Add(new TextBlock { Text = label }); panel.Children.Add(combo);
        string previousChoice = value;
        combo.SelectionChanged += (_, _) =>
        {
            var choice = combo.SelectedItem as string ?? "";
            if (choice == previousChoice) return;
            previousChoice = choice;
            SetField(owner, key, JsonValue.Create(choice), optional && choice == "");
        };
    }
    private void RenderDetails()
    {
        try { RenderSchemaDetails(); }
        catch (Exception ex)
        {
            details.Children.Clear();
            details.Children.Add(new TextBlock { Text = "Maske konnte nicht aus dem Schema erstellt werden:\n" + ex.Message, TextWrapping = Avalonia.Media.TextWrapping.Wrap });
        }
    }
    private void RenderSchemaDetails()
    {
        details.Children.Clear();
        if (selected is null || document.Services[selected] is not JsonObject service)
        {
            details.Children.Add(new TextBlock { Text = "JSON-Datei öffnen oder einen Service hinzufügen." }); return;
        }
        var serviceName = selected;
        details.Children.Add(Row(new TextBlock { Text = serviceName, FontSize = 20 }, Button("Umbenennen", async () =>
        {
            var name = await Prompt("Service umbenennen", serviceName);
            if (name is null) return;
            document.Rename(serviceName, name); SelectService(name); Changed();
        })));
        var general = new StackPanel { Spacing = 6 };
        var serviceSchema = document.Describe("service");
        var groupSchema = document.Describe("group");
        var memberSchema = document.Describe("member");
        SchemaFields(general, service, serviceSchema, "portgroups");
        general.Children.Add(new TextBlock { Text = "task=delete bleibt ein Auftrag in der Datei. „Löschen“ entfernt den Eintrag aus der Datei.", TextWrapping = Avalonia.Media.TextWrapping.Wrap, FontSize = 11 });
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
            panel.Children.Add(new TextBlock { Text = "Ports (durch Komma getrennt; Regeln siehe Schema)" }); panel.Children.Add(ports);
            string? previousPorts = ports.Text;
            ports.TextChanged += (_, _) =>
            {
                if (ports.Text == previousPorts) return;
                previousPorts = ports.Text;
                var values = new JsonArray();
                foreach (var token in (ports.Text ?? "").Split(',', StringSplitOptions.TrimEntries))
                {
                    if (string.IsNullOrWhiteSpace(ports.Text)) break;
                    values.Add(int.TryParse(token, NumberStyles.None, CultureInfo.InvariantCulture, out int number) ? JsonValue.Create(number) : JsonValue.Create(token));
                }
                SetField(group, "ports", values);
            };
            SchemaFields(panel, group, groupSchema, "ports", "members");
            panel.Children.Add(new TextBlock { Text = "Server / Mitglieder", FontWeight = Avalonia.Media.FontWeight.SemiBold });
            if (group["members"] is JsonArray members)
                foreach (var memberNode in members.ToArray())
                {
                    var member = (JsonObject)memberNode!;
                    var fields = new StackPanel { Spacing = 4 };
                    SchemaFields(fields, member, memberSchema);
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
    private void SchemaFields(StackPanel panel, JsonObject owner, JsonObject definition, params string[] excluded)
    {
        var properties = definition["properties"] as JsonObject ?? new JsonObject();
        var required = (definition["required"] as JsonArray)?.Select(n => n?.ToString()).ToHashSet() ?? new HashSet<string?>();
        foreach (string key in properties.Select(p => p.Key).Concat(owner.Select(p => p.Key)).Distinct().Except(excluded))
        {
            var spec = properties[key] as JsonObject ?? new JsonObject();
            string label = spec["title"]?.ToString() ?? key;
            bool optional = !required.Contains(key);
            string? type = spec["type"] is JsonValue t && t.TryGetValue<string>(out var typeName) ? typeName : null;
            var values = spec["enum"] as JsonArray;
            bool stringValue = owner[key] is null || owner[key] is JsonValue v && v.TryGetValue<string>(out _);
            if (stringValue && values is not null && values.All(n => n is JsonValue ev && ev.TryGetValue<string>(out _)))
                Choice(panel, owner, key, label, (optional ? new[] { "" } : Array.Empty<string>()).Concat(values.Select(n => n!.GetValue<string>())).ToArray(), optional);
            else if (type == "string" && stringValue)
                TextField(panel, owner, key, label, optional);
            else if (type == "boolean" && (owner[key] is null || owner[key] is JsonValue bv && bv.TryGetValue<bool>(out _)))
            {
                var checkbox = new CheckBox { Name = key, Content = label, IsThreeState = true,
                    IsChecked = owner[key]?.GetValue<bool>() };
                bool? previousCheck = checkbox.IsChecked;
                checkbox.IsCheckedChanged += (_, _) =>
                {
                    if (checkbox.IsChecked == previousCheck) return;
                    previousCheck = checkbox.IsChecked;
                    SetField(owner, key, checkbox.IsChecked is bool value ? JsonValue.Create(value) : null, checkbox.IsChecked is null);
                };
                panel.Children.Add(checkbox);
            }
            else if (type is "integer" or "number")
            {
                var number = new TextBox { Name = key, Text = owner[key]?.ToJsonString() ?? "", PlaceholderText = optional ? "Optional" : "Pflichtfeld" };
                panel.Children.Add(new TextBlock { Text = label }); panel.Children.Add(number);
                string? previousNumber = number.Text;
                number.TextChanged += (_, _) =>
                {
                    if (number.Text == previousNumber) return;
                    previousNumber = number.Text;
                    if (string.IsNullOrWhiteSpace(number.Text) && optional) SetField(owner, key, null, true);
                    else
                    {
                        try { SetField(owner, key, ServiceDocument.ParseUnique(number.Text ?? "")); }
                        catch (System.Text.Json.JsonException) { SetField(owner, key, JsonValue.Create(number.Text ?? "")); }
                    }
                };
            }
            else
            {
                panel.Children.Add(new TextBlock { Text = label });
                panel.Children.Add(Button(key + " als JSON bearbeiten …", () => EditJson(label, owner[key]?.ToJsonString(new() { WriteIndented = true }) ?? spec["default"]?.ToJsonString() ?? "null", text =>
                { owner[key] = ServiceDocument.ParseUnique(text); Changed(); RenderDetails(); })));
            }
            if (spec["description"] is JsonValue description)
                panel.Children.Add(new TextBlock { Text = description.ToString(), FontSize = 11, TextWrapping = Avalonia.Media.TextWrapping.Wrap });
            if (optional && owner.ContainsKey(key))
                panel.Children.Add(Button(key + " entfernen", () => { owner.Remove(key); Changed(); RenderDetails(); return Task.CompletedTask; }));
        }
    }

    private async Task ChooseSchema()
    {
        var files = await StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions { Title = "JSON-Schema wählen", AllowMultiple = false, FileTypeFilter = new[] { JsonType } });
        if (files.Count == 0) return;
        document.SetSchema(files[0].TryGetLocalPath() ?? throw new IOException("Bitte ein lokales Schema wählen."));
        Validate(); RenderDetails();
        settings?.SaveSchema(document.SchemaPath);
    }

    private Task EditDocumentJson() => EditJson("Dokument als JSON bearbeiten", document.Json, text =>
    {
        document.ReplaceJson(text); Changed(); RefreshList(selected); Validate();
    });

    private async Task EditJson(string title, string initial, Action<string> apply)
    {
        var input = new TextBox { Text = initial, AcceptsReturn = true, Height = 360, FontFamily = new Avalonia.Media.FontFamily("monospace") };
        while (await Dialog(title, "JSON eingeben. Die Schema-Prüfung erfolgt vor dem Speichern.", input, new[] { "Übernehmen", "Abbrechen" }) == "Übernehmen")
        {
            try { apply(input.Text ?? ""); return; }
            catch (Exception ex) when (ex is System.Text.Json.JsonException or InvalidDataException)
            { await Message("Ungültiges JSON", ex.Message); }
            // A control can only have one visual parent.
            if (input.Parent is Panel parent) parent.Children.Remove(input);
        }
    }

    private static string NextGroup(JsonObject? groups)
    {
        int i = 1; while (groups?.ContainsKey($"portgroup{i:000}") == true) i++;
        return $"portgroup{i:000}";
    }
    private void CheckGroupName(string name) => document.CheckName("groups", name);
    private async Task AddService()
    {
        var name = await Prompt("Service hinzufügen", "service-neu");
        if (name is null) return;
        document.CheckName("services", name);
        if (document.Services.ContainsKey(name)) throw new InvalidDataException("Service bereits vorhanden.");
        document.Services.Add(name, ServiceDocument.NewService()); Changed(); SelectService(name);
    }
    private async Task DuplicateService()
    {
        if (selected is null) return;
        var source = selected;
        var name = await Prompt("Service duplizieren", source + "-kopie");
        if (name is null) return;
        document.CheckName("services", name);
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
        var candidate = new ServiceDocument(document.SchemaPath);
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
