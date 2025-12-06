import '../models/availability.dart';
import '../models/court.dart';
import '../services/court_service.dart';

/// Repository for court data operations
/// Acts as a single source of truth, abstracting data sources
class CourtRepository {
  final CourtService _courtService;

  // In-memory cache
  List<Court> _cachedCourts = [];
  Court? _selectedCourt;

  CourtRepository({CourtService? courtService})
    : _courtService = courtService ?? CourtService();

  /// Get cached courts
  List<Court> get cachedCourts => List.unmodifiable(_cachedCourts);

  /// Get selected court
  Court? get selectedCourt => _selectedCourt;

  /// Set selected court
  set selectedCourt(Court? court) => _selectedCourt = court;

  /// Fetch courts from API
  Future<List<Court>> fetchCourts({
    int page = 1,
    int limit = 10,
    String? district,
    bool forceRefresh = false,
  }) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _cachedCourts.isNotEmpty && page == 1) {
      return _cachedCourts;
    }

    final response = await _courtService.getCourts(
      page: page,
      limit: limit,
      district: district,
    );

    if (response.success && response.data != null) {
      if (page == 1) {
        _cachedCourts = response.data!;
      } else {
        _cachedCourts.addAll(response.data!);
      }
      return response.data!;
    }

    throw Exception(response.error?.message ?? 'Failed to fetch courts');
  }

  /// Fetch court by ID
  Future<Court> fetchCourtById(String id) async {
    // Check cache first
    final cachedCourt = _cachedCourts.where((c) => c.id == id).firstOrNull;
    if (cachedCourt != null) {
      return cachedCourt;
    }

    final response = await _courtService.getCourtById(id);

    if (response.success && response.data != null) {
      return response.data!;
    }

    throw Exception(response.error?.message ?? 'Court not found');
  }

  /// Fetch nearby courts
  Future<List<Court>> fetchNearbyCourts({
    required double latitude,
    required double longitude,
    double radius = 5,
  }) async {
    final response = await _courtService.getNearbyCourts(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );

    if (response.success && response.data != null) {
      return response.data!;
    }

    throw Exception(response.error?.message ?? 'Failed to fetch nearby courts');
  }

  /// Fetch court availability for a specific date
  Future<CourtAvailability> fetchCourtAvailability({
    required String courtId,
    required String date,
  }) async {
    final response = await _courtService.getCourtAvailability(
      courtId: courtId,
      date: date,
    );

    if (response.success && response.data != null) {
      return response.data!;
    }

    throw Exception(response.error?.message ?? 'Failed to fetch court availability');
  }

  /// Clear cache
  void clearCache() {
    _cachedCourts = [];
    _selectedCourt = null;
  }

  /// Dispose
  void dispose() {
    _courtService.dispose();
  }
}
