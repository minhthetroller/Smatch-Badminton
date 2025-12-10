import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/config/mapbox_config.dart';
import 'core/theme/app_theme.dart';
import 'repositories/court_repository.dart';
import 'services/court_service.dart';
import 'services/location_service.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/map_view_model.dart';
import 'view_models/search_view_model.dart';
import 'views/map_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

  // Initialize Mapbox access token
  // Get your token from https://account.mapbox.com/access-tokens/
  MapboxOptions.setAccessToken(MapboxConfig.accessToken);

  runApp(const SmatchBadmintonApp());
}

class SmatchBadmintonApp extends StatelessWidget {
  const SmatchBadmintonApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create shared instances
    final courtService = CourtService();
    final courtRepository = CourtRepository(courtService: courtService);
    final locationService = LocationService();

    return MultiProvider(
      providers: [
        // Auth ViewModel - manages authentication state
        ChangeNotifierProvider(
          create: (_) => AuthViewModel()..initialize(),
        ),
        // Map View Model
        ChangeNotifierProvider(
          create: (_) => MapViewModel(
            courtRepository: courtRepository,
            locationService: locationService,
          ),
        ),
        // Search View Model
        ChangeNotifierProvider(
          create: (_) => SearchViewModel(courtRepository: courtRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Smatch Badminton',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Wrapper widget that handles auth initialization state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        // Show loading screen while initializing
        if (!authViewModel.isInitialized) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF2E7D32),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show main app once initialized
        return const MapView();
      },
    );
  }
}
