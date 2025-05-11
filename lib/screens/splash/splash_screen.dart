import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:monexa/screens/onboarding/onboarding_screen1.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

    @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen1()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7F3DFF),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow/Blur efek
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.5), 
                    blurRadius: 70,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
            // Text "monexa"
            Text(
              'Monexa',
              style: GoogleFonts.inter(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0,

              ),
            ),
          ],
        ),
      ),
    );
  }
}
