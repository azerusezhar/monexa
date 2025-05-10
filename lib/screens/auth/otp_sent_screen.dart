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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read, size: 100, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Kode OTP telah dikirim!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Cek email kamu:\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Mengalihkan ke halaman verifikasi...'),
            ],
          ),
        ),
      ),
    );
  }
}
