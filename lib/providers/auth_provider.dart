import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Define the Authentication States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// 2. Create the Notifier using the modern Riverpod 2.0+ syntax
class AuthNotifier extends Notifier<AuthState> {
  late final SupabaseClient _supabase;

  @override
  AuthState build() {
    _supabase = Supabase.instance.client;
    
    // Check if the user is already logged in when the app starts
    final session = _supabase.auth.currentSession;
    if (session != null && session.user != null) {
      return AuthAuthenticated(session.user!);
    }
    
    // Default starting state
    return AuthInitial();
  }

  // --- SIGN UP ---
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = AuthLoading();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName}, // Save name to user metadata
      );
      
      if (response.user != null) {
        state = AuthAuthenticated(response.user!);
      } else {
        state = AuthError('Signup failed. Please try again.');
      }
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('An unexpected error occurred.');
    }
  }

  // --- SIGN IN ---
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = AuthLoading();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        state = AuthAuthenticated(response.user!);
      } else {
        state = AuthError('Login failed. Please check your credentials.');
      }
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('An unexpected error occurred.');
    }
  }

  // --- SIGN OUT ---
  Future<void> signOut() async {
    state = AuthLoading();
    try {
      await _supabase.auth.signOut();
      state = AuthInitial();
    } catch (e) {
      state = AuthError('Error signing out.');
    }
  }

  // --- RESET PASSWORD ---
  Future<void> resetPassword(String email) async {
    state = AuthLoading();
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      state = AuthInitial();
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('An unexpected error occurred.');
    }
  }

  // --- UPDATE PASSWORD (AFTER RECOVERY) ---
  Future<void> updatePassword(String newPassword) async {
    state = AuthLoading();
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      // If successful, the user is now fully authenticated with the new password
      state = AuthAuthenticated(_supabase.auth.currentUser!);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('An unexpected error occurred while updating the password.');
    }
  }
}

// 3. Expose the Provider to the rest of the app using NotifierProvider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});