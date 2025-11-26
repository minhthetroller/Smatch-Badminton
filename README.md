# Arc Badminton

A Flutter application to find badminton courts near you, featuring a Google Maps-like UI with Mapbox integration and vector tiles from pg_tileserv.

## Features

- 🗺️ **Interactive Map**: Mapbox-powered map with vector tiles
- 📍 **Location Services**: Find courts near your current location
- 🔍 **Search**: Search for badminton courts by name or district
- 🏸 **Court Information**: View court details, opening hours, amenities
- 📱 **Modern UI**: Google Maps-inspired interface with category chips and floating buttons

## Architecture

This app follows the **MVVM (Model-View-ViewModel)** architecture pattern:

```
lib/
├── core/
│   ├── config/      # App configuration (Mapbox, etc.)
│   ├── constants/   # API and Map constants
│   └── theme/       # App theme and styling
├── models/          # Data models (Court, ApiResponse, etc.)
├── repositories/    # Data abstraction layer
├── services/        # API and location services
├── view_models/     # Business logic and state management
└── views/
    └── widgets/     # Reusable UI components
```

## Setup

### Prerequisites

- Flutter SDK ^3.10.1
- Dart SDK ^3.10.1
- Mapbox account (for access token)
- Backend server running at `http://192.168.1.7:3000`

### 1. Get Mapbox Access Token

1. Create a Mapbox account at [mapbox.com](https://www.mapbox.com/)
2. Go to [Account > Access Tokens](https://account.mapbox.com/access-tokens/)
3. Create a new token or use the default public token

### 2. Configure Mapbox Token

#### Option A: Environment Variable (Recommended)

```bash
export MAPBOX_ACCESS_TOKEN=pk.your_token_here
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN
```

#### Option B: iOS Configuration

Add to `ios/Runner/Info.plist`:
```xml
<key>MBXAccessToken</key>
<string>YOUR_MAPBOX_ACCESS_TOKEN</string>
```

#### Option C: Android Configuration

Add to `android/app/src/main/AndroidManifest.xml` inside `<application>`:
```xml
<meta-data
    android:name="MAPBOX_ACCESS_TOKEN"
    android:value="YOUR_MAPBOX_ACCESS_TOKEN" />
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the App

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# With Mapbox token
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token_here
```

## Backend API

The app connects to a backend server for:

- **Courts API**: `/api/courts` - CRUD operations for badminton courts
- **Map Tiles API**: `/api/map-tiles/{z}/{x}/{y}.pbf` - Vector tiles from pg_tileserv

See the [API Documentation](./API.md) for full details.

### Map Layers

1. **Base Layer**: Mapbox Streets style
2. **Courts Layer**: Vector tiles from pg_tileserv displaying court locations

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| provider | ^6.1.2 | State management |
| mapbox_maps_flutter | ^2.12.0 | Map display |
| http | ^1.2.2 | API calls |
| geolocator | ^13.0.2 | Location services |
| permission_handler | ^11.3.1 | Permission handling |

## Project Structure

### Models
- `Court` - Badminton court data
- `ApiResponse` - Generic API response wrapper
- `CategoryItem` - Filter category chips

### Services
- `ApiService` - Base HTTP client
- `CourtService` - Court API operations
- `LocationService` - GPS and location

### Repositories
- `CourtRepository` - Court data management with caching

### ViewModels
- `MapViewModel` - Map state and user location
- `SearchViewModel` - Search and filtering

### Views & Widgets
- `MapView` - Main map screen
- `MapSearchBar` - Google-style search bar
- `CategoryChips` - Horizontal filter chips
- `MapFloatingButtons` - Map control buttons
- `BottomNavBar` - Navigation bar
- `CourtCard` - Court info card

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.
