# App Icons Setup

To set up the Smatch app icon:

1. Save your app icon as `app_icon.png` (1024x1024 pixels, square) in this folder
2. Optionally, save `app_icon_foreground.png` for Android adaptive icons
3. Run the following command to generate all icon sizes:

```bash
flutter pub run flutter_launcher_icons
```

## Icon Requirements

- **app_icon.png**: Main app icon (1024x1024 px, PNG format)
- **app_icon_foreground.png**: (Optional) Foreground layer for Android adaptive icons
- Use the Smatch green (#2E7D32) as the primary brand color

## Brand Colors

- Primary Green: `#2E7D32`
- Light Green: `#4CAF50`
- Dark Green: `#1B5E20`
- Background: `#FFFFFF`

