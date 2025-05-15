import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:monexa/screens/dashboard/dashboard_screen.dart';
import 'package:monexa/screens/onboarding/onboarding_screen1.dart';
import 'package:monexa/screens/profiles/setup_profile_screen.dart';
import 'package:monexa/screens/pin/setup_pin_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus(); 
  }

Future<void> checkLoginStatus() async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  if (user == null) {
    await Future.delayed(const Duration(seconds: 3));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen1()),
    );
    return;
  }


  final Map<String, dynamic>? profile = await client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle()
      .catchError((_) => null);

  await Future.delayed(const Duration(seconds: 3));

  if (profile == null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SetupProfileScreen()),
    );
  } else if (profile['pin_hash'] == null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SetupPinScreen()),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }
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
