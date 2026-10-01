// Omunchy Firefox defaults: skip first-run, dark UI and content, userChrome on.
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.theme.toolbar-theme", 0);
user_pref("browser.theme.content-theme", 0);
user_pref("layout.css.prefers-color-scheme.content-override", 0);
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
