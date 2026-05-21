# pg_tileserv Health Check & Backend Integration Guide

## ✅ Status: WORKING — Data is being served correctly

pg_tileserv is running at `http://localhost:7800` and returning real court data.

---

## 1. Discovered Layers

Two sources are exposed:

| ID | Type | Description |
|----|------|-------------|
| `public.courts` | **Table layer** | Direct serve of the `courts` table |
| `public.courts_tile` | **Function layer** | Custom MVT function |

---

## 2. Tile URL Formats

### Table Layer (Recommended — currently working)
```
GET http://localhost:7800/public.courts/{z}/{x}/{y}.pbf
```

### Function Layer
```
GET http://localhost:7800/public.courts_tile/{z}/{x}/{y}.pbf
```

### Info endpoints
```
GET http://localhost:7800/index.json                  → lists all layers
GET http://localhost:7800/public.courts.json          → metadata + bounds + properties
GET http://localhost:7800/public.courts_tile.json     → metadata for function layer
```

---

## 3. Parameters

Both tile URLs take **only path parameters** — no query string needed for the table layer:

| Parameter | Where | Description |
|-----------|-------|-------------|
| `{z}` | path | Zoom level (0–22) |
| `{x}` | path | Tile X coordinate |
| `{y}` | path | Tile Y coordinate |

The function layer (`courts_tile`) also takes **no extra arguments** (confirmed from `.json` metadata: `"arguments": []`).

---

## 4. What to Expect in the Response

**Format:** `application/vnd.mapbox-vector-tile` (Mapbox Vector Tile / `.pbf`)

**Layer name inside the tile:** `public.courts`

> [!IMPORTANT]
> The source layer name you must reference in Mapbox/Flutter is **`public.courts`** (dot-separated, with schema prefix). This is already correct in `MapConstants.courtsSourceLayer`.

### Feature geometry
- **Type:** `Point`
- **Coordinates:** tile-local pixel coordinates (0–4096 extent), NOT lon/lat

### Feature properties (all available in every tile)

| Property | Type | Example |
|----------|------|---------|
| `id` | `String` (UUID) | `"58ec0256-5e36-4925-9a4a-2ceaf3116707"` |
| `name` | `String` | `"Sân cầu lông Thanh Xuân"` |
| `description` | `String` | `"Trung tâm cầu lông lớn nhất quận Thanh Xuân"` |
| `phone_numbers` | `String` | `"{0923456789,0934567890}"` |
| `address_street` | `String` | `"Số 120 Nguyễn Trãi"` |
| `address_ward` | `String` | `"Phường Thanh Xuân Trung"` |
| `address_district` | `String` | `"Quận Thanh Xuân"` |
| `address_city` | `String` | `"Hà Nội"` |
| `mon`–`sun` | `String` | `"05:00-23:00"` (opening hours per day) |
| `created_at` | `String` | `"2026-03-19 06:22:33.228394+00"` |
| `updated_at` | `String` | `"2026-03-19 06:22:33.228394+00"` |

> [!NOTE]
> `phone_numbers` comes as a PostgreSQL array string like `{0923456789,0934567890}`. Parse with: `value.replaceAll('{','').replaceAll('}','').split(',')`.
>
> Opening hours (`mon`, `tue`, ..., `sun`) are flattened from the `opening_hours` JSONB column into individual day properties.
>
> `details` JSONB is **not** present in the tile (excluded during MVT generation — likely too complex for protobuf).

---

## 5. Data Available — Zoom Level Test Results

Tests run against actual court locations in Hanoi (lon≈105.83, lat≈21.01):

| Zoom | Tile Example | Data? | Size |
|------|-------------|-------|------|
| 6 | `6/54/28` | ❌ Empty | 0 bytes |
| 8 | `8/203/112` | ✅ **5 courts** | 1913 bytes |
| 10 | `10/813/450` | ✅ **5 courts** | 1569 bytes |
| 12 | `12/3252/1803` | ✅ **3 courts** | 913 bytes |
| 13 | `13/6504/3607` | ✅ **2 courts** | 581 bytes |
| 14 | `14/13008/7213` | ⚠️ Empty (wrong tile) | 0 bytes |
| 14 | `14/13006/7212` | ✅ Data exists | 603 bytes |

> [!WARNING]
> The Flutter app defaults to **zoom 14.0**, centered at `[105.8194, 21.0227]`. At this zoom, the court data IS present in tiles but spread across multiple z14 tiles. The map should work — but if courts aren't showing, verify the Flutter camera is not drifting off the correct tile bounds.

---

## 6. Flutter / Mapbox Integration

### Source configuration (in your Flutter map setup)
```dart
// Source
await mapboxMap.style.addSource(VectorSource(
  id: MapConstants.courtsSourceId,
  tiles: ['http://localhost:7800/public.courts/{z}/{x}/{y}.pbf'],
  minzoom: 7,      // Data starts appearing at ~z8
  maxzoom: 16,     // pg_tileserv serves up to z22 but data gets sparse at z15+
));
```

### Layer configuration
```dart
// The sourceLayer MUST be exactly 'public.courts'
await mapboxMap.style.addLayer(CircleLayer(
  id: MapConstants.courtsLayerId,
  sourceId: MapConstants.courtsSourceId,
  sourceLayer: 'public.courts',   // ← This is the critical field
  circleRadius: MapConstants.courtMarkerRadius,
  circleColor: MapConstants.courtMarkerColor,
  circleStrokeWidth: MapConstants.courtMarkerStrokeWidth,
  circleStrokeColor: MapConstants.courtMarkerStrokeColor,
));
```

### Querying clicked features
When a user taps the map, the queried feature's `.properties` map will contain all the fields listed in Section 4. Access like:
```dart
final name = feature.properties['name'] as String;
final id = feature.properties['id'] as String;
final hours = feature.properties['mon'] as String; // e.g. "05:00-23:00"
```

---

## 7. Quick curl Tests

```bash
# Check server is up + list layers
curl http://localhost:7800/index.json

# Get layer metadata (bounds, properties, zoom range)
curl http://localhost:7800/public.courts.json

# Fetch a real tile with data (z8, covers all Hanoi courts)
curl -o tile.pbf http://localhost:7800/public.courts/8/203/112.pbf
ls -la tile.pbf  # Should be ~1913 bytes

# Fetch tile for default camera position at z13
curl -o tile.pbf http://localhost:7800/public.courts/13/6504/3607.pbf
ls -la tile.pbf  # Should be ~581 bytes
```
