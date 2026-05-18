import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_mobile/core/services/fcm_service.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  @override
  Stream<AuthState> build() {
    return Supabase.instance.client.auth.onAuthStateChange;
  }

  Future<void> signIn(String email, String password) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp(String email, String password, {Map<String, dynamic>? data}) async {
    await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<void> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      serverClientId:
          '49185547481-5oedne01p4or15n42svra2saiatmirck.apps.googleusercontent.com',
    );
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;
    final accessToken = googleAuth?.accessToken;
    final idToken = googleAuth?.idToken;

    if (idToken == null) {
      throw 'Sign in with Google was cancelled or failed.';
    }

    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> signOut() async {
    try {
      await FCMService.instance.deleteTokenFromSupabase();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_store_id');
    await Supabase.instance.client.auth.signOut();
    await GoogleSignIn().signOut();
  }
}

@riverpod
User? currentUser(CurrentUserRef ref) {
  return Supabase.instance.client.auth.currentUser;
}
