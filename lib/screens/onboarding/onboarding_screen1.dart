import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:monexa/screens/onboarding/onboarding_screen2.dart';

class OnboardingScreen1 extends StatefulWidget {
  const OnboardingScreen1({super.key});

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1> with TickerProviderStateMixin {
  late final AnimationController _controller;

  // Animasi untuk setiap elemen
  late final Animation<double> _fadeImage;
  late final Animation<double> _scaleImage;
  late final Animation<double> _fadeTitle;
  late final Animation<double> _fadeSubtitle;
  late final Animation<double> _fadeButtons;
  
  // Animasi subtle untuk pergerakan
  late final Animation<Offset> _slideTitle;
  late final Animation<Offset> _slideSubtitle;
  late final Animation<Offset> _slideImage;

  @override
  void initState() {
    super.initState();

    // Durasi yang lebih singkat untuk animasi yang lebih responsif
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Animasi image: fade in dengan slide dan scale
    _fadeImage = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );
    
    // Animasi scale untuk gambar
    _scaleImage = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    
    // Animasi slide untuk gambar (dari bawah ke atas secara subtle)
    _slideImage = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // Animasi title: fade in dengan sedikit pergerakan ke atas
    _fadeTitle = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    
    // Slide yang lebih subtle (jarak yang lebih pendek)
    _slideTitle = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Animasi subtitle: fade in dengan sedikit pergerakan ke atas
    _fadeSubtitle = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    
    _slideSubtitle = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Animasi button: fade in sederhana
    _fadeButtons = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
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
              // Image dengan animasi fade, scale dan slide
              SlideTransition(
                position: _slideImage,
                child: ScaleTransition(
                  scale: _scaleImage,
                  child: FadeTransition(
                    opacity: _fadeImage,
                    child: Image.asset(
                      'assets/images/onboarding1.png',
                      height: 300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Title dengan animasi fade dan slide subtle
              SlideTransition(
                position: _slideTitle,
                child: FadeTransition(
                  opacity: _fadeTitle,
                  child: Text(
                    'Gain total control\nof your money',
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
              // Subtitle dengan animasi fade dan slide subtle
              SlideTransition(
                position: _slideSubtitle,
                child: FadeTransition(
                  opacity: _fadeSubtitle,
                  child: Text(
                    'Become your own money manager\nand make every cent count',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Indikator dot dan button dengan animasi fade
              FadeTransition(
                opacity: _fadeButtons,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(true),
                        const SizedBox(width: 6),
                        _buildDot(false),
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
                              builder: (_) => const OnboardingScreen2(),
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