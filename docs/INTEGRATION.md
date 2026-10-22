# Theme authority integration

Prism owns all theme mutations and assignments. The consumer contract remains intentionally small:

- Theme files: `~/Library/Application Support/AINCRAD/themes/<id>.json`
- Global assignment: `theme` in `~/Library/Application Support/AINCRAD/settings.json`
- Browser assignment: `theme` in `~/Library/Application Support/AINCRAD Browser/preferences.json`; `follow` means global
- Refresh notifications: `com.djag.aincrad.themeChanged` and `com.djag.aincrad.browser.prefsChanged`

AINCRAD's Themes settings tab and writable status-menu selector were removed. Browser's Look pane now displays its assignment without editing it. Discovery already only reads the global assignment. Consumer fallback rendering remains in each app so missing files never prevent an app from launching.
