import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:monexa/screens/splash/splash_screen.dart';
import 'package:monexa/setup_success_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monexa/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  await dotenv.load();
  
  // Initialize Supabase
await Supabase.initialize(
  url: Constants.supabaseUrl,
  anonKey: Constants.supabaseAnonKey,
);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monexa',
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home:  const SetupSuccessScreen(),
    );
  }
}