import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:monexa/screens/auth/login_screen.dart';
import 'package:monexa/screens/auth/register_screen.dart';

class OnboardingScreen3 extends StatefulWidget {
  const OnboardingScreen3({super.key});

  @override
  State<OnboardingScreen3> createState() => _OnboardingScreen3State();
}

class _OnboardingScreen3State extends State<OnboardingScreen3> with TickerProviderStateMixin {
  late final AnimationController _controller;
  
  // Animasi untuk elemen terpisah pada gambar
  late final Animation<double> _fadeImage;
  late final Animation<double> _scaleImage;
  
  // Animasi untuk teks
  late final Animation<double> _fadeTitle;
  late final Animation<double> _fadeSubtitle;
  late final Animation<double> _fadeButtons;
  
  // Animasi untuk efek staggered pada teks
  late final Animation<Offset> _slideTitle;
  late final Animation<Offset> _slideSubtitle;
  
  // Animasi khusus untuk highlight pada tombol
  late final Animation<double> _pulseButton;
  late final Animation<double> _fadeSignInButton;

  @override
  void initState() {
    super.initState();

    // Durasi animasi yang konsisten dengan screen sebelumnya
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Animasi gambar: fade dan scale dengan efek "spring"
    _fadeImage = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _scaleImage = Tween<double>(begin: 1.1, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    
    // Animasi judul dengan stagger effect
    _fadeTitle = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    
    // Slide dari bawah dengan jarak sedikit lebih pendek
    _slideTitle = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Animasi subtitle dengan sedikit delay
    _fadeSubtitle = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    _slideSubtitle = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Animasi button area dengan slight pulse effect
    _fadeButtons = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 0.9, curve: Curves.easeOut),
      ),
    );
    
    // Pulse effect untuk tombol sign up (sedikit lebih besar kemudian normal)
    _pulseButton = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.98, end: 1.03).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.03, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.85, 1.0),
      ),
    );
    
    // Animasi khusus untuk tombol sign in (muncul sedikit lebih lambat)
    _fadeSignInButton = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
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
              // Animasi gambar dengan scale down dan spring effect
              ScaleTransition(
                scale: _scaleImage,
                child: FadeTransition(
                  opacity: _fadeImage,
                  child: Image.asset(
                    'assets/images/onboarding3.png',
                    height: 300,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Animasi title dengan slide dari bawah
              SlideTransition(
                position: _slideTitle,
                child: FadeTransition(
                  opacity: _fadeTitle,
                  child: Text(
                    'Planning ahead\nmade easy',
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
              // Animasi subtitle dengan slide dari bawah
              SlideTransition(
                position: _slideSubtitle,
                child: FadeTransition(
                  opacity: _fadeSubtitle,
                  child: Text(
                    'Set up budgets that are easy to stick to\nand plan for future expenses',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Dot indicator dan button dengan animasi pulse
              FadeTransition(
                opacity: _fadeButtons,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(false),
                        const SizedBox(width: 6),
                        _buildDot(false),
                        const SizedBox(width: 6),
                        _buildDot(true),
                      ],
                    ),
                    const SizedBox(height: 44),
                    ScaleTransition(
                      scale: _pulseButton,
                      child: Column(
                        children: [
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
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign Up',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeSignInButton,
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEE5FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Sign In',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: const Color(0xFF7F3DFF),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
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