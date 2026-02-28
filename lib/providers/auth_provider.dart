import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

// 1. Define the Authentication States
abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}
// NEW: We need a dedicated state for catching the reset link
class AuthPasswordRecovery extends AuthState {} 

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// 2. Create the Notifier using the modern Riverpod syntax
class AuthNotifier extends Notifier<AuthState> {
  late final SupabaseClient _supabase;

  @override
  AuthState build() {
    _supabase = Supabase.instance.client;
    
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.passwordRecovery) {
        state = AuthPasswordRecovery();
      } else if (event == AuthChangeEvent.signedIn && session != null) {
        // CRITICAL FIX 1: Don't let auto-login overwrite the recovery state!
        // Supabase signs the user in during recovery, but they MUST stay on the update screen.
        if (state is! AuthPasswordRecovery) {
          state = AuthAuthenticated(session.user);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        state = AuthInitial();
      } else if (event == AuthChangeEvent.initialSession) {
        // CRITICAL FIX 2: Explicitly handle the initial session resolution.
        if (session != null) {
          state = AuthAuthenticated(session.user);
        } else {
          state = AuthInitial();
        }
      }
    }, onError: (error) {
      // Catch any potential stream errors gracefully
      state = AuthError(error.toString());
    });

    // ---------------------------------------------------------
    // CRITICAL FIX: The Failsafe Timeout
    // ---------------------------------------------------------
    // If Supabase swallows an expired/used token and never emits an event,
    // don't let the app freeze on the Splash Screen forever.
    Future.delayed(const Duration(seconds: 4), () {
      if (state is AuthLoading) {
        final session = _supabase.auth.currentSession;
        if (session != null) {
          state = AuthAuthenticated(session.user);
        } else {
          // If 4 seconds have passed and we have no session, the link 
          // was likely dead/consumed. Kick them to the login screen.
          state = AuthInitial(); 
        }
      }
    });

    // Default starting state forces the splash screen to wait
    return AuthLoading();
  }

  // --- SIGN UP ---
  Future<void> signUp({required String email, required String password, required String fullName}) async {
    state = AuthLoading();
    try {
      final response = await _supabase.auth.signUp(
        email: email, password: password, data: {'full_name': fullName},
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
  Future<void> signIn({required String email, required String password}) async {
    state = AuthLoading();
    try {
      final response = await _supabase.auth.signInWithPassword(email: email, password: password);
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
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      // Manually push to authenticated state after successful update
      state = AuthAuthenticated(_supabase.auth.currentUser!);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('An unexpected error occurred while updating the password.');
    }
  }
}

// 3. Expose the Provider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});