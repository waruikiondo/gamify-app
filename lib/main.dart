import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'core/theme.dart';
import 'core/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final posthogKey = dotenv.env['POSTHOG_API_KEY'];
  if (posthogKey != null && posthogKey.isNotEmpty) {
    final config = PostHogConfig(posthogKey);
    config.host = 'https://us.i.posthog.com';
    config.captureApplicationLifecycleEvents = true;
    config.debug = false;
    await Posthog().setup(config);
  }

  runApp(
    const ProviderScope(
      child: FlyDroneApp(),
    ),
  );
}

class FlyDroneApp extends ConsumerStatefulWidget {
  const FlyDroneApp({super.key});

  @override
  ConsumerState<FlyDroneApp> createState() => _FlyDroneAppState();
}

class _FlyDroneAppState extends ConsumerState<FlyDroneApp> {
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