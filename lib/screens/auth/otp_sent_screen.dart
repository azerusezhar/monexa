import 'dart:async';
import 'package:flutter/material.dart';
import 'package:monexa/screens/auth/otp_recovery_screen.dart';

class OtpSentScreen extends StatefulWidget {
  final String email;

  const OtpSentScreen({super.key, required this.email});

  @override
  State<OtpSentScreen> createState() => _OtpSentScreenState();
}

class _OtpSentScreenState extends State<OtpSentScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpRecoveryScreen(email: widget.email),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/email_sent.png', 
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'Code has been sent to your email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Check your email:\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                color: Color(0xFF7F3DFF), 
              ),
              const SizedBox(height: 16),
              const Text(
                'Redirecting to verification page...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}