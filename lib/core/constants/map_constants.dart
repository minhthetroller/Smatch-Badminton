import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Map-related constants
class MapConstants {
  MapConstants._();

  /// Default map center (Hanoi, Vietnam - RMIT area from the image)
  static const double defaultLatitude = 21.0227;
  static const double defaultLongitude = 105.8194;

  /// Default zoom level
  static const double defaultZoom = 14.0;

  /// Minimum and maximum zoom levels
  static const double minZoom = 0.0;
  static const double maxZoom = 22.0;

  /// Default camera position
  static CameraOptions get defaultCameraOptions => CameraOptions(
    center: Point(coordinates: Position(defaultLongitude, defaultLatitude)),
    zoom: defaultZoom,
  );

  /// Vector tile source ID
  static const String courtsSourceId = 'courts-source';

  /// Vector tile layer IDs
  static const String courtsLayerId = 'courts-layer';
  static const String courtsTextLayerId = 'courts-text-layer';

  /// Source layer name (from pg_tileserv)
  static const String courtsSourceLayer = 'courts';

  /// Court marker colors
  static const int courtMarkerColor = 0xFFFF5722; // Orange
  static const int courtMarkerStrokeColor = 0xFFFFFFFF; // White

  /// Court marker sizes
  static const double courtMarkerRadius = 8.0;
  static const double courtMarkerStrokeWidth = 2.0;

  /// Court text label styling
  static const int courtTextColor = 0xFF333333; // Dark gray
  static const int courtTextHaloColor = 0xFFFFFFFF; // White halo
  static const double courtTextSize = 12.0;
  static const double courtTextHaloWidth = 1.5;
  static const double courtTextOffset = 1.5; // Offset from marker
}
