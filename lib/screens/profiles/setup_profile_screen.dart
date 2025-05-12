import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:monexa/pin/setup_pin_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  XFile? _pickedImage;
  String? _avatarUrl;

  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser!.id;

      if (_pickedImage != null) {
        final fileName = path.basename(_pickedImage!.path);

        // Upload ke Supabase
        await client.storage
            .from('avatars')
            .upload(
              '$userId/$fileName',
              File(_pickedImage!.path),
            );

        // Ambil URL publik
        final publicUrl = client.storage
            .from('avatars')
            .getPublicUrl('$userId/$fileName');
        _avatarUrl = publicUrl;
      }

      // Simpan ke tabel profiles
      await client.from('profiles').insert({
        'id': userId,
        'full_name': _fullNameController.text,
        'username': _usernameController.text,
        'avatar_url': _avatarUrl,
        'phone': _phoneController.text.trim(),
      });

      // Lanjut ke setup PIN
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SetupPinScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Let’s set up your profile",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "This will help us know you better.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 16),
                  ),
                  const SizedBox(height: 40),

                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFF292B2D),
                        backgroundImage:
                            _pickedImage != null
                                ? FileImage(File(_pickedImage!.path))
                                : null,
                        child:
                            _pickedImage == null
                                ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white.withOpacity(0.4),
                                )
                                : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        "Upload Photo",
                        style: TextStyle(
                          color: const Color(0xFF7F3DFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Phone Number Field
                  TextFormField(
                    controller: _phoneController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      labelStyle: TextStyle(color: Colors.white60),
                      hintText: "08123456789",
                      hintStyle: TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Please enter your phone number";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Full Name Field
                  TextFormField(
                    controller: _fullNameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      labelStyle: TextStyle(color: Colors.white60),
                      hintText: "Your full name",
                      hintStyle: TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Please enter your name";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Username",
                      labelStyle: TextStyle(color: Colors.white60),
                      hintText: "Your username",
                      hintStyle: TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Please enter a username";
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F3DFF),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              "Next",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
