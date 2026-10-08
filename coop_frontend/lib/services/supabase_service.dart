import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  bool get isAuthenticated => client.auth.currentSession != null;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Sign in failed');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
    if (response.user == null) {
      throw Exception('Sign up failed');
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> sendOtp({
    required String email,
  }) async {
    await client.auth.signInWithOtp(
      email: email,
    );
  }

  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    await client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }
}
