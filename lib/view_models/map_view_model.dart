import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../core/constants/map_constants.dart';
import '../models/court.dart';
import '../repositories/court_repository.dart';
import '../services/location_service.dart';

/// View state for the map
enum MapViewState { initial, loading, loaded, error }

/// ViewModel for the map view
class MapViewModel extends ChangeNotifier {
  final CourtRepository _courtRepository;
  final LocationService _locationService;

  MapViewModel({
    CourtRepository? courtRepository,
    LocationService? locationService,
  }) : _courtRepository = courtRepository ?? CourtRepository(),
       _locationService = locationService ?? LocationService();

  // State
  MapViewState _state = MapViewState.initial;
  String? _errorMessage;
  geo.Position? _currentPosition;
  List<Court> _nearbyCourts = [];
  Court? _selectedCourt;
  bool _isLocationEnabled = false;
  bool _isLoadingCourtDetails = false;

  // Map controller
  MapboxMap? _mapboxMap;

  // Getters
  MapViewState get state => _state;
  String? get errorMessage => _errorMessage;
  geo.Position? get currentPosition => _currentPosition;
  List<Court> get nearbyCourts => _nearbyCourts;
  Court? get selectedCourt => _selectedCourt;
  bool get isLocationEnabled => _isLocationEnabled;
  bool get isLoadingCourtDetails => _isLoadingCourtDetails;
  MapboxMap? get mapboxMap => _mapboxMap;

  /// Initialize map controller
  void setMapboxMap(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    notifyListeners();
  }

  /// Initialize the view model
  Future<void> initialize() async {
    _setState(MapViewState.loading);

    try {
      // Get current location
      await _getCurrentLocation();

      // Load nearby courts if location is available
      if (_currentPosition != null) {
        await loadNearbyCourts();
      }

      _setState(MapViewState.loaded);
    } catch (e) {
      _setError('Failed to initialize: ${e.toString()}');
    }
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    // Check if location services are enabled
    final serviceEnabled = await _locationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check and request permission
    var permission = await _locationService.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await _locationService.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        return false;
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      return false;
    }

    _isLocationEnabled = true;
    notifyListeners();
    return true;
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await _locationService.openAppSettings();
  }

  /// Get current location
  Future<void> _getCurrentLocation() async {
    _currentPosition = await _locationService.getCurrentPosition();
    _isLocationEnabled = _currentPosition != null;
  }

  /// Move camera to current location
  Future<void> moveToCurrentLocation() async {
    if (_mapboxMap == null) return;

    // First request permission if needed
    if (!_isLocationEnabled) {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return;
    }

    // Get fresh position
    _currentPosition = await _locationService.getCurrentPosition();

    if (_currentPosition != null) {
      await _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              _currentPosition!.longitude,
              _currentPosition!.latitude,
            ),
          ),
          zoom: MapConstants.defaultZoom,
        ),
        MapAnimationOptions(duration: 1000),
      );

      // Update location puck
      await _updateLocationPuck();
    }
    notifyListeners();
  }

  /// Update location puck to show user's current position
  Future<void> _updateLocationPuck() async {
    if (_mapboxMap == null) return;

    try {
      await _mapboxMap!.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          showAccuracyRing: true,
        ),
      );
    } catch (e) {
      debugPrint('Error updating location puck: $e');
    }
  }

  /// Move camera to a specific location
  Future<void> moveToLocation(
    double latitude,
    double longitude, {
    double? zoom,
  }) async {
    if (_mapboxMap == null) return;

    await _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)),
        zoom: zoom ?? MapConstants.defaultZoom,
      ),
      MapAnimationOptions(duration: 1000),
    );
    notifyListeners();
  }

  /// Load nearby courts
  Future<void> loadNearbyCourts({double radius = 5}) async {
    if (_currentPosition == null) return;

    try {
      _nearbyCourts = await _courtRepository.fetchNearbyCourts(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: radius,
      );
      notifyListeners();
    } catch (e) {
      // Silently fail for nearby courts
      debugPrint('Failed to load nearby courts: $e');
    }
  }

  /// Fetch court details by ID from API
  /// Optionally provide latitude/longitude to center the map immediately
  Future<void> fetchCourtById(
    String courtId, {
    double? latitude,
    double? longitude,
  }) async {
    // Skip if same court is already selected
    if (_selectedCourt?.id == courtId) {
      return;
    }

    _isLoadingCourtDetails = true;
    notifyListeners();

    // Center map immediately if coordinates provided (from search suggestion)
    if (latitude != null && longitude != null) {
      await moveToLocation(latitude, longitude, zoom: 16);
    }

    try {
      final court = await _courtRepository.fetchCourtById(courtId);
      _selectedCourt = court;
      _courtRepository.selectedCourt = court;

      // Move to court location if available and coordinates weren't provided
      if (latitude == null && longitude == null && court.location != null) {
        await moveToLocation(
          court.location!.latitude,
          court.location!.longitude,
          zoom: 16,
        );
      }
    } catch (e) {
      debugPrint('Failed to fetch court details: $e');
      _errorMessage = 'Failed to load court details';
    } finally {
      _isLoadingCourtDetails = false;
      notifyListeners();
    }
  }

  /// Select a court (used when we already have court data)
  void selectCourt(Court? court) {
    _selectedCourt = court;
    _courtRepository.selectedCourt = court;

    if (court?.location != null) {
      moveToLocation(
        court!.location!.latitude,
        court.location!.longitude,
        zoom: 16,
      );
    }
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedCourt = null;
    _courtRepository.selectedCourt = null;
    notifyListeners();
  }

  /// Refresh data
  Future<void> refresh() async {
    _setState(MapViewState.loading);

    try {
      await _getCurrentLocation();
      if (_currentPosition != null) {
        await loadNearbyCourts();
      }
      _setState(MapViewState.loaded);
    } catch (e) {
      _setError('Failed to refresh: ${e.toString()}');
    }
  }

  // Private helpers
  void _setState(MapViewState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _state = MapViewState.error;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _courtRepository.dispose();
    super.dispose();
  }
}
