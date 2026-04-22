import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();

    // 1. Initialize the video
    _videoController = VideoPlayerController.asset('assets/videos/splash_video.mp4')
      ..initialize().then((_) {
        // Mute the video to ensure it auto-plays smoothly on iOS and Android
        _videoController.setVolume(0.0);
        _videoController.setLooping(true);
        _videoController.play();
        
        // Refresh the UI once the video is loaded
        setState(() {});
      });

    // 2. Wait 3 seconds, then check Auth and navigate
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        context.go('/dashboard');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fallback color while video loads
      body: Stack(
        fit: StackFit.expand,
        children: [
          // LAYER 1: The Video Background
          if (_videoController.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            ),

          // LAYER 2: Dark Overlay (Ensures text/logos are always visible)
          Container(
            color: Colors.black.withValues(alpha: 0.6), 
          ),

          // LAYER 3: Your 2flydrone Branding
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Logo from your Login Screen
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.cyanAccent, AppTheme.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4), 
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A0F14),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '2FD',
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  '2FLYDRONE', 
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.w900, 
                    color: Colors.white, 
                    letterSpacing: 4.0
                  )
                ),
                const SizedBox(height: 8),
                const Text(
                  'FLIGHT ACADEMY', 
                  style: TextStyle(
                    color: Colors.cyanAccent, 
                    fontSize: 14, 
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}