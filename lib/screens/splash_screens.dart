import 'dart:async';
import 'package:flutter/material.dart';
import 'register_screens.dart';

/// -----------------------------------------------------------
/// RECŌRA — PROFESSIONAL MODERN SPLASH UI
/// Matching style of the Login Screen (Dark Navy + Teal)
/// Smooth fade animation + glow + modern branding
/// -----------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  static const Color primary = Color(0xFF0B1B3A); // Deep Navy
  static const Color accent = Color(0xFF00C2A8); // Teal

  @override
  void initState() {
    super.initState();

    /// Animation setup
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    /// Navigate after splash
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: Stack(
        children: [
          /// Soft gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, Color(0xFF071029)],
              ),
            ),
          ),

          /// Center content
          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// Logo circle
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withOpacity(0.15),
                        border: Border.all(color: accent, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.folder_copy_rounded,
                        size: 60,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 25),
                    /// App name
                    const Text(
                      'Recora',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    /// Tagline
                    Text(
                      'Keep your records organized',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 45),

                    /// Loading indicator
                    const CircularProgressIndicator(
                      strokeWidth: 3,
                      color: accent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}