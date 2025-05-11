import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SupabaseService {
  final SupabaseClient client;

  SupabaseService(this.client);

  // Sign in dengan Google
  Future<void> signInWithGoogle() async {
    const webClientId = '47596589937-8nhal7stp55mb29r5osdr0ueans4m77b.apps.googleusercontent.com';
    final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: webClientId);
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;
    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }
    await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  // Registrasi pengguna dengan email dan password
  Future<AuthResponse> registerUser(String email, String password) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null, // Untuk menggunakan OTP verifikasi manual
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Update password pengguna
  Future<void> updatePassword(String newPassword) async {
    try {
      await client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      rethrow;
    }
  }

  // Login pengguna dengan email dan password
  Future<AuthResponse> loginUser(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Kirim ulang email verifikasi
  Future<void> resendVerificationEmail(String email) async {
    try {
      await client.auth.resend(type: OtpType.signup, email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Verifikasi OTP untuk registrasi atau login
  Future<AuthResponse> verifyOTP(String email, String token) async {
    try {
      final response = await client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup, // Sesuaikan dengan jenis OTP yang digunakan
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Kirim email reset password dengan OTP
  Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: null, // Gunakan OTP untuk reset manual
      );
    } catch (e) {
      rethrow;
    }
  }

  // Verifikasi OTP untuk reset password dan update password baru
  Future<AuthResponse> verifyPasswordReset(
    String email,
    String token,
    String newPassword,
  ) async {
    try {
      // Verifikasi OTP
      final response = await client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery, // Jenis OTP untuk recovery password
      );

      // Jika OTP berhasil, update password
      if (response.user != null) {
        await client.auth.updateUser(UserAttributes(password: newPassword));
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Logout pengguna
  Future<void> logoutUser() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Mengecek apakah pengguna sudah terautentikasi
  bool isAuthenticated() {
    return client.auth.currentUser != null;
  }
}