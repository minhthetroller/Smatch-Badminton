import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'core/config/mapbox_config.dart';
import 'core/theme/app_theme.dart';
import 'repositories/court_repository.dart';
import 'services/court_service.dart';
import 'services/location_service.dart';
import 'view_models/map_view_model.dart';
import 'view_models/search_view_model.dart';
import 'views/map_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Mapbox access token
  // Get your token from https://account.mapbox.com/access-tokens/
  MapboxOptions.setAccessToken(MapboxConfig.accessToken);

  runApp(const ArcBadmintonApp());
}

class ArcBadmintonApp extends StatelessWidget {
  const ArcBadmintonApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create shared instances
    final courtService = CourtService();
    final courtRepository = CourtRepository(courtService: courtService);
    final locationService = LocationService();

    return MultiProvider(
      providers: [
        // View Models
        ChangeNotifierProvider(
          create: (_) => MapViewModel(
            courtRepository: courtRepository,
            locationService: locationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchViewModel(courtRepository: courtRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Arc Badminton',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MapView(),
      ),
    );
  }
}
