import 'package:flutter/material.dart';
import '../core/theme.dart';

class RankScreen extends StatelessWidget {
  const RankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'GLOBAL RANKING', 
          style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Icon Wrapper
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.leaderboard_rounded, size: 80, color: AppTheme.primary),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Calculating Percentiles...', 
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Your global rank and test percentages will appear here once enough learners have completed the final certification exam.\n\nKeep training to secure a place in the Top 1%!', 
                textAlign: TextAlign.center, 
                style: TextStyle(color: AppTheme.textGrey, fontSize: 14, height: 1.5)
              ),
            ],
          ),
        ),
      ),
    );
  }
}