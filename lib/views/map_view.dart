import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../core/config/mapbox_config.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/map_constants.dart';
import '../core/theme/app_theme.dart';
import '../view_models/map_view_model.dart';
import '../view_models/search_view_model.dart';
import 'booking_view.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/category_chips.dart';
import 'widgets/court_bottom_sheet.dart';
import 'widgets/court_search_anchor.dart';
import 'widgets/map_floating_buttons.dart';

/// Main map view that displays the Google Maps-like UI
class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize view models after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map layer
          const _MapLayer(),

          // Overlay UI
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Search bar with autocomplete
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Consumer<MapViewModel>(
                    builder: (context, mapVM, _) {
                      return CourtSearchAnchor(
                        hintText: 'Search here',
                        selectedCourtName: mapVM.selectedCourt?.name,
                        onSuggestionSelected: (suggestion) {
                          // Fetch court details when a suggestion is selected
                          // Pass coordinates to center map immediately
                          mapVM.fetchCourtById(
                            suggestion.id,
                            latitude: suggestion.latitude,
                            longitude: suggestion.longitude,
                          );
                        },
                        onClear: () {
                          // Clear selection when X button is pressed
                          mapVM.clearSelection();
                        },
                        onVoiceSearch: () {
                          // TODO: Implement voice search
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Category chips
                Consumer<SearchViewModel>(
                  builder: (context, searchVM, _) {
                    return CategoryChips(
                      categories: searchVM.categories,
                      onCategoryTap: (category) {
                        searchVM.selectCategory(category.id);
                      },
                    );
                  },
                ),

                const Spacer(),

                // Floating buttons on the right
                Consumer<MapViewModel>(
                  builder: (context, mapVM, _) {
                    // Hide floating buttons when court is selected
                    if (mapVM.selectedCourt != null) {
                      return const SizedBox.shrink();
                    }
                    return Align(
                      alignment: Alignment.centerRight,
                      child: MapFloatingButtons(
                        onLayersTap: () {
                          _showLayersBottomSheet(context);
                        },
                        onMyLocationTap: () {
                          _handleMyLocationTap(context, mapVM);
                        },
                        onDirectionsTap: () {
                          // TODO: Implement directions
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // Court Details & Skeleton Area
          Consumer<MapViewModel>(
            builder: (context, mapVM, _) {
              Widget content = const SizedBox.shrink(key: ValueKey('empty'));

              if (mapVM.isLoadingCourtDetails) {
                content = const _CourtLoadingSkeleton(key: ValueKey('skeleton'));
              } else if (mapVM.selectedCourt != null) {
                content = CourtBottomSheet(
                  key: const ValueKey('sheet'),
                  court: mapVM.selectedCourt!,
                  onClose: () => mapVM.clearSelection(),
                  onDirections: () {
                    // TODO: Open directions
                  },
                  onBook: () {
                    // Navigate to booking view
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BookingView(
                          court: mapVM.selectedCourt!,
                        ),
                      ),
                    );
                  },
                );
              }

              final bool hasContent =
                  mapVM.isLoadingCourtDetails || mapVM.selectedCourt != null;

              return Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutQuart,
                  switchOutCurve: Curves.easeInQuart,
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                  child: hasContent
                      ? Container(
                          key: const ValueKey('content-container'),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: content,
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              );
            },
          ),
        ],
      ),
      // Use extendBody to prevent map from resizing when bottom nav hides
      extendBody: true,
      bottomNavigationBar: Consumer<MapViewModel>(
        builder: (context, mapVM, _) {
          final isHidden = mapVM.selectedCourt != null || mapVM.isLoadingCourtDetails;
          // Use AnimatedContainer to smoothly hide/show bottom nav without layout shift
          return AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            offset: isHidden ? const Offset(0, 1) : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isHidden ? 0 : 1,
              child: MapBottomNavBar(
                currentIndex: _currentNavIndex,
                items: MapBottomNavBar.defaultItems,
                onTap: (index) {
                  setState(() {
                    _currentNavIndex = index;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleMyLocationTap(
      BuildContext context, MapViewModel mapVM) async {
    // Request location permission and move to current location
    final hasPermission = await mapVM.requestLocationPermission();

    if (!hasPermission && context.mounted) {
      // Show dialog asking to enable location
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Permission'),
          content: const Text(
            'Location permission is required to show your current location on the map. '
            'Would you like to enable it in settings?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                mapVM.openLocationSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return;
    }

    // Move to current location
    await mapVM.moveToCurrentLocation();
  }

  void _showLayersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Map type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _LayerOption(
                    icon: Icons.map,
                    label: 'Default',
                    isSelected: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  _LayerOption(
                    icon: Icons.satellite,
                    label: 'Satellite',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  _LayerOption(
                    icon: Icons.terrain,
                    label: 'Terrain',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _LayerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _LayerOption({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppTheme.primaryColor, width: 2)
                  : null,
            ),
            child: Icon(
              icon,
              size: 28,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Map layer widget that handles Mapbox map rendering
class _MapLayer extends StatefulWidget {
  const _MapLayer();

  @override
  State<_MapLayer> createState() => _MapLayerState();
}

class _MapLayerState extends State<_MapLayer> {
  MapboxMap? _mapboxMap;

  @override
  void dispose() {
    _mapboxMap = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show error if Mapbox token is not configured
    if (!MapboxConfig.isConfigured) {
      return _buildTokenErrorWidget();
    }

    return MapWidget(
      cameraOptions: MapConstants.defaultCameraOptions,
      styleUri: MapboxStyles.MAPBOX_STREETS,
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: _onStyleLoaded,
      onTapListener: _onMapTap,
    );
  }

  Widget _buildTokenErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Mapbox Access Token Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please configure your Mapbox access token to display the map.\n\n'
                'Run with:\nflutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_token',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    debugPrint('Map created');

    // Set map controller in view model
    if (mounted) {
      context.read<MapViewModel>().setMapboxMap(mapboxMap);
    }

    // Hide compass and attribution
    _hideMapControls();

    // Try to setup layers after a short delay
    // This handles cases where onStyleLoaded doesn't fire (e.g., after hot restart)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _mapboxMap != null) {
        _setupCourtLayers();
        _enableLocationPuck();
      }
    });
  }

  /// Hide compass, logo, and attribution from the map
  Future<void> _hideMapControls() async {
    if (_mapboxMap == null) return;

    try {
      // Hide compass
      await _mapboxMap!.compass.updateSettings(
        CompassSettings(enabled: false),
      );

      // Hide scale bar
      await _mapboxMap!.scaleBar.updateSettings(
        ScaleBarSettings(enabled: false),
      );

      // Hide attribution (move to bottom-left and make it minimal)
      await _mapboxMap!.attribution.updateSettings(
        AttributionSettings(
          position: OrnamentPosition.BOTTOM_LEFT,
          marginLeft: 8,
          marginBottom: 8,
        ),
      );

      // Hide logo (move to bottom-left)
      await _mapboxMap!.logo.updateSettings(
        LogoSettings(
          position: OrnamentPosition.BOTTOM_LEFT,
          marginLeft: 8,
          marginBottom: 24,
        ),
      );

      debugPrint('Map controls hidden successfully');
    } catch (e) {
      debugPrint('Error hiding map controls: $e');
    }
  }

  /// Enable user location puck (blue dot)
  Future<void> _enableLocationPuck() async {
    if (_mapboxMap == null) return;

    try {
      // Enable location component with blue puck
      await _mapboxMap!.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          pulsingColor: AppTheme.primaryColor.toARGB32(),
          pulsingMaxRadius: 50.0,
          showAccuracyRing: true,
          accuracyRingColor: AppTheme.primaryColor.withValues(alpha: 0.2).toARGB32(),
          accuracyRingBorderColor: AppTheme.primaryColor.toARGB32(),
        ),
      );

      debugPrint('Location puck enabled successfully');
    } catch (e) {
      debugPrint('Error enabling location puck: $e');
    }
  }

  /// Handle tap on map to detect court clicks
  Future<void> _onMapTap(MapContentGestureContext gestureContext) async {
    if (_mapboxMap == null) return;

    final screenCoordinate = gestureContext.touchPosition;

    // Query features at the tapped point for both circle and text layers
    final features = await _mapboxMap!.queryRenderedFeatures(
      RenderedQueryGeometry.fromScreenCoordinate(screenCoordinate),
      RenderedQueryOptions(
        layerIds: [MapConstants.courtsLayerId, MapConstants.courtsTextLayerId],
      ),
    );

    if (features.isNotEmpty && mounted) {
      final feature = features.first;
      final properties = feature?.queriedFeature.feature['properties'];

      if (properties != null && properties is Map) {
        // Extract court ID from properties
        final courtId = (properties['id'])?.toString();

        if (courtId != null) {
          debugPrint('Court tapped: $courtId');
          // Fetch court details from API
          context.read<MapViewModel>().fetchCourtById(courtId);
        }
      }
    } else {
      // Tapped on empty area - clear selection
      if (mounted) {
        context.read<MapViewModel>().clearSelection();
      }
    }
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData eventData) async {
    if (_mapboxMap == null) return;

    debugPrint('Style loaded event fired, adding sources and layers...');

    // Always try to set up sources and layers when style loads
    // This handles hot restart and rebuild scenarios
    await _setupCourtLayers();

    // Enable location puck after style is loaded
    await _enableLocationPuck();
  }

  /// Set up all court-related sources and layers
  Future<void> _setupCourtLayers() async {
    if (_mapboxMap == null) return;

    try {
      // Check if source already exists
      final sourceExists = await _sourceExists(MapConstants.courtsSourceId);
      
      if (sourceExists) {
        debugPrint('Court layers already exist, skipping setup');
        return;
      }

      // Add vector tile source from pg_tileserv
      await _addCourtsTileSource();

      // Add layers to display courts
      await _addCourtsCircleLayer();
      await _addCourtsTextLayer();

      debugPrint('All court layers setup completed');
    } catch (e) {
      debugPrint('Error setting up court layers: $e');
    }
  }

  /// Check if a source exists
  Future<bool> _sourceExists(String sourceId) async {
    if (_mapboxMap == null) return false;
    try {
      final source = await _mapboxMap!.style.getSource(sourceId);
      return source != null;
    } catch (e) {
      return false;
    }
  }

  /// Add vector tile source from the backend
  Future<void> _addCourtsTileSource() async {
    if (_mapboxMap == null) return;

    try {
      // Create vector source for courts from pg_tileserv
      await _mapboxMap!.style.addSource(
        VectorSource(
          id: MapConstants.courtsSourceId,
          tiles: [ApiConstants.mapTilesTemplate],
          minzoom: MapConstants.minZoom,
          maxzoom: MapConstants.maxZoom,
        ),
      );
      debugPrint('Courts vector tile source added successfully');
    } catch (e) {
      debugPrint('Error adding courts source: $e');
    }
  }

  /// Add circle layer to display court markers
  Future<void> _addCourtsCircleLayer() async {
    if (_mapboxMap == null) return;

    try {
      await _mapboxMap!.style.addLayer(
        CircleLayer(
          id: MapConstants.courtsLayerId,
          sourceId: MapConstants.courtsSourceId,
          sourceLayer: MapConstants.courtsSourceLayer,
          circleRadius: MapConstants.courtMarkerRadius,
          circleColor: MapConstants.courtMarkerColor,
          circleStrokeWidth: MapConstants.courtMarkerStrokeWidth,
          circleStrokeColor: MapConstants.courtMarkerStrokeColor,
        ),
      );
      debugPrint('Courts circle layer added successfully');
    } catch (e) {
      debugPrint('Error adding courts circle layer: $e');
    }
  }

  /// Add text layer to display court names above markers
  Future<void> _addCourtsTextLayer() async {
    if (_mapboxMap == null) return;

    try {
      await _mapboxMap!.style.addLayer(
        SymbolLayer(
          id: MapConstants.courtsTextLayerId,
          sourceId: MapConstants.courtsSourceId,
          sourceLayer: MapConstants.courtsSourceLayer,
          // Get the 'name' property from vector tile features
          textField: '{name}',
          textSize: MapConstants.courtTextSize,
          textColor: MapConstants.courtTextColor,
          textHaloColor: MapConstants.courtTextHaloColor,
          textHaloWidth: MapConstants.courtTextHaloWidth,
          // Position text above the circle marker
          textOffset: [0, -MapConstants.courtTextOffset],
          textAnchor: TextAnchor.BOTTOM,
          // Text styling
          textMaxWidth: 10,
          textFont: ['Open Sans Semibold', 'Arial Unicode MS Bold'],
          // Allow text overlap for dense areas (optional)
          textAllowOverlap: false,
          iconAllowOverlap: false,
        ),
      );
      debugPrint('Courts text layer added successfully');
    } catch (e) {
      debugPrint('Error adding courts text layer: $e');
    }
  }
}

/// Loading skeleton that mimics the court bottom sheet structure with slide-up animation
class _CourtLoadingSkeleton extends StatefulWidget {
  const _CourtLoadingSkeleton({super.key});

  @override
  State<_CourtLoadingSkeleton> createState() => _CourtLoadingSkeletonState();
}

class _CourtLoadingSkeletonState extends State<_CourtLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    // Shimmer animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
          height: screenHeight * 0.45,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header skeleton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(width: 200, height: 20),
                          const SizedBox(height: 8),
                          _buildShimmerBox(width: 150, height: 14),
                          const SizedBox(height: 6),
                          _buildShimmerBox(width: 180, height: 14),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildShimmerCircle(40),
                        const SizedBox(width: 8),
                        _buildShimmerCircle(40),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons skeleton
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildShimmerBox(width: 80, height: 44, borderRadius: 22),
                    const SizedBox(width: 10),
                    _buildShimmerBox(width: 110, height: 44, borderRadius: 22),
                    const SizedBox(width: 10),
                    _buildShimmerBox(width: 70, height: 44, borderRadius: 22),
                    const SizedBox(width: 10),
                    _buildShimmerBox(width: 70, height: 44, borderRadius: 22),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Photo gallery skeleton
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildShimmerBox(width: 180, height: 140, borderRadius: 12),
                    const SizedBox(width: 10),
                    _buildShimmerBox(width: 180, height: 140, borderRadius: 12),
                    const SizedBox(width: 10),
                    _buildShimmerBox(width: 100, height: 140, borderRadius: 12),
                  ],
                ),
              ),

              SizedBox(height: bottomPadding + 20),
            ],
          ),
        ),
      );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double borderRadius = 4,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCircle(double size) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
