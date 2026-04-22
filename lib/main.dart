import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added for environment variables

import 'core/theme.dart';
import 'core/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the environment variables from the .env file
  await dotenv.load(fileName: ".env");

  // Initialize Supabase Backend securely using the .env variables
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    // Wrap the app in ProviderScope so Riverpod works globally
    const ProviderScope(
      child: 2FlyDroneApp(),
    ),
  );
}

class 2FlyDroneApp extends ConsumerStatefulWidget {
  const 2FlyDroneApp({super.key});

  @override
  ConsumerState<2FlyDroneApp> createState() => _2FlyDroneAppState();
}

class _2FlyDroneAppState extends ConsumerState<2FlyDroneApp> {
  @override
  void initState() {
    super.initState();
    
    // Listen for deep links / auth events from Supabase
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      
      // If the user arrives via a password recovery link
      if (event == AuthChangeEvent.passwordRecovery) {
        // Use the router provider to navigate to the update password screen
        ref.read(routerProvider).go('/update-password');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Read the router configuration from our provider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '2FlyDrone',
      theme: AppTheme.darkTheme, // Apply your custom dark theme
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}