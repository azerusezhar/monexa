import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:monexa/screens/onboarding/onboarding_screens3.dart';

class OnboardingScreen2 extends StatefulWidget {
  const OnboardingScreen2({super.key});

  @override
  State<OnboardingScreen2> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2> with TickerProviderStateMixin {
  late final AnimationController _controller;
  
  // Animasi untuk gambar dengan efek berbeda
  late final Animation<double> _fadeImage;
  late final Animation<double> _rotateImage;
  late final Animation<double> _scaleImage;
  
  // Animasi untuk teks
  late final Animation<double> _fadeTitle;
  late final Animation<double> _fadeSubtitle;
  late final Animation<double> _fadeButtons;
  
  // Animasi pergerakan
  late final Animation<Offset> _slideTitle;
  late final Animation<Offset> _slideSubtitle;

  @override
  void initState() {
    super.initState();

    // Durasi yang sesuai untuk animasi responsif
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Animasi gambar dengan rotate dan scale
    _fadeImage = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    
    // Rotasi yang sangat subtle - hanya 5 derajat
    _rotateImage = Tween<double>(begin: -0.09, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutBack),
      ),
    );
    
    // Scale dari sedikit lebih kecil ke ukuran normal
    _scaleImage = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Animasi title: fade dengan slide dari samping
    _fadeTitle = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    
    _slideTitle = Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Animasi subtitle: fade dengan slide dari samping, sedikit delay
    _fadeSubtitle = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    _slideSubtitle = Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Animasi button area: simple fade
    _fadeButtons = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.10),
              // Animasi gambar dengan rotasi dan scale
              FadeTransition(
                opacity: _fadeImage,
                child: ScaleTransition(
                  scale: _scaleImage,
                  child: RotationTransition(
                    turns: _rotateImage,
                    child: Image.asset(
                      'assets/images/onboarding2.png',
                      height: 300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Animasi judul dengan slide dari samping
              SlideTransition(
                position: _slideTitle,
                child: FadeTransition(
                  opacity: _fadeTitle,
                  child: Text(
                    'Know where your\nmoney goes',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 17),
              // Animasi subtitle dengan slide dari samping
              SlideTransition(
                position: _slideSubtitle,
                child: FadeTransition(
                  opacity: _fadeSubtitle,
                  child: Text(
                    'Track your transaction easily,\nwith categories and financial report',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Dot indicator dan button
              FadeTransition(
                opacity: _fadeButtons,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(false),
                        const SizedBox(width: 6),
                        _buildDot(true),
                        const SizedBox(width: 6),
                        _buildDot(false),
                      ],
                    ),
                    const SizedBox(height: 44),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A3FFC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OnboardingScreen3(),
                            ),
                          );
                        },
                        child: Text(
                          'Continue',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF8A3FFC) : Colors.grey[700],
        shape: BoxShape.circle,
      ),
    );
  }
}