import 'dart:io';

import 'package:flutter/material.dart';
import 'package:monexa/screens/onboarding/onboarding_screen1.dart';
import 'package:monexa/screens/profiles/profiles_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _fullNameController;

  String? _avatarUrl;
  bool _isLoading = true;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Upload ke Supabase Storage
      final file = File(pickedFile.path);
      final fileName = 'avatars/${DateTime.now().millisecondsSinceEpoch}.png';

      try {
        // Mengupload gambar ke Supabase Storage
        final _ = await _supabase.storage
            .from('avatars')
            .upload(fileName, file);

        // Mendapatkan URL gambar yang baru diupload
        final avatarUrl = _supabase.storage
            .from('avatars')
            .getPublicUrl(fileName);

        setState(() {
          _avatarUrl = avatarUrl;
        });

        // Simpan URL avatar ke database profiles
        final user = _supabase.auth.currentUser;
        if (user != null) {
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'avatar_url': avatarUrl,
          });
        }
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  Future<void> _loadProfileData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response =
          await _supabase.from('profiles').select().eq('id', user.id).single();

      setState(() {
        _usernameController = TextEditingController(
          text: response['username'] ?? '',
        );
        _emailController = TextEditingController(text: user.email ?? '');
        _phoneController = TextEditingController(text: response['phone'] ?? '');
        _fullNameController = TextEditingController(
          text: response['full_name'] ?? '',
        );
        _avatarUrl = response['avatar_url'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _usernameController = TextEditingController();
        _emailController = TextEditingController();
        _phoneController = TextEditingController();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('profiles').upsert({
        'id': user.id,
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {}
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body:
          _isLoading
              ? _buildShimmerLoader()
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildAvatarSection(),
                      const SizedBox(height: 32),
                      _buildFormFieldsCard(),
                      const SizedBox(height: 32),
                      _buildDangerZoneCard(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildAvatarSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7F3DFF),
                  Color(0xFF5F1FFF),
                  Color(0xFF3D00FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7F3DFF).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(70),
                child:
                    _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null,
                              ),
                            );
                          },
                        )
                        : Container(
                          color: Colors.grey.shade900,
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white54,
                          ),
                        ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3D3D3D), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFieldsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildFormField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.person_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Username required';
              if (value.length < 3) return 'Minimum 3 characters';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _fullNameController,
            label: 'Full Name',
            icon: Icons.person_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Full name required';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_rounded,
            enabled: false,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _phoneController,
            label: 'Phone',
            icon: Icons.phone_rounded,
            validator: (value) {
              if (value!.isNotEmpty &&
                  !RegExp(
                    r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$',
                  ).hasMatch(value)) {
                return 'Invalid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: ElevatedButton(
              onPressed: () {
                _saveProfile();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF7F3DFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 8,
                shadowColor: Colors.deepPurpleAccent.withOpacity(0.4),
                side: BorderSide(
                  color: Colors.deepPurpleAccent.withOpacity(0.6),
                  width: 1,
                ),
                minimumSize: Size(
                  double.infinity,
                  50,
                ), // Full width and height of 50
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool enabled = true,
    int maxLines = 1,
    bool counter = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        floatingLabelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Container(
          width: 50,
          height: 50,
          margin: const EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF7F3DFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF7F3DFF), size: 20),
        ),
        suffixIcon:
            counter
                ? Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: Text(
                    '${controller.text.length}/150',
                    style: TextStyle(color: Colors.white.withOpacity(0.4)),
                  ),
                )
                : null,
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7F3DFF), width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
      validator: validator,
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade900.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red.shade300),
              const SizedBox(width: 10),
              Text(
                'Danger Zone',
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Permanent actions cannot be undone. Proceed with caution.',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(Icons.delete_forever, color: Colors.red.shade300),
              label: Text(
                'Delete Account',
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.red.shade900.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _showDeleteConfirmation(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade800,
        highlightColor: Colors.grey.shade700,
        child: Column(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ...List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Delete Account?',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'This will permanently remove all your data. This action cannot be undone.',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const OnboardingScreen1()));
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
