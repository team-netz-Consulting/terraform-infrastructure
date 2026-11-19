using Avalonia;
using Avalonia.Controls;
using Avalonia.Controls.Primitives;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Styling;
using Avalonia.Themes.Fluent;

namespace ServicesEditor;

internal static class Program
{
    [STAThread]
    public static void Main(string[] args) => BuildAvaloniaApp().StartWithClassicDesktopLifetime(args);
    public static AppBuilder BuildAvaloniaApp() => AppBuilder.Configure<App>().UsePlatformDetect();
}

public sealed class App : Application
{
    public override void Initialize()
    {
        Styles.Add(new FluentTheme());
        Styles.Add(new Style(selector => selector.Is<TemplatedControl>())
        {
            Setters = { new Setter(TemplatedControl.FontSizeProperty, 12d) }
        });
        Styles.Add(new Style(selector => selector.OfType<TextBlock>())
        {
            Setters = { new Setter(TextBlock.FontSizeProperty, 12d) }
        });
    }
    public override void OnFrameworkInitializationCompleted()
    {
        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
        {
            var settings = new AppSettingsStore();
            var startup = settings.Load();
            desktop.MainWindow = new MainWindow(startup.SchemaPath, settings, startup.Notice);
        }
        base.OnFrameworkInitializationCompleted();
    }
}
