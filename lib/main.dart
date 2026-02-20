import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart'; // Added to access router

import 'core/theme.dart';
import 'core/router.dart';

// TODO: Replace with your actual Supabase credentials from your Supabase Dashboard
const supabaseUrl = 'https://pxvurufjxyogyfyejlwp.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB4dnVydWZqeHlvZ3lmeWVqbHdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzOTUxMDEsImV4cCI6MjA4Njk3MTEwMX0.hHP_P9ohsq03-NRb87Y5tKgDF1t9q4vI_5waMn0aaVA';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Backend
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    // Wrap the app in ProviderScope so Riverpod works globally
    const ProviderScope(
      child: GamifyApp(),
    ),
  );
}

class GamifyApp extends ConsumerStatefulWidget {
  const GamifyApp({super.key});

  @override
  ConsumerState<GamifyApp> createState() => _GamifyAppState();
}

class _GamifyAppState extends ConsumerState<GamifyApp> {
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
      title: 'Gamify',
      theme: AppTheme.darkTheme, // Apply your custom dark theme
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}