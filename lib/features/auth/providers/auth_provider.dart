import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_mobile/core/services/fcm_service.dart';
import 'package:pos_mobile/core/services/analytics_service.dart';

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
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await AnalyticsService.instance.setUserId(user.id);
    }
    await AnalyticsService.instance.logLogin(method: 'email');
  }

  Future<void> signUp(String email, String password, {Map<String, dynamic>? data}) async {
    await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
    await AnalyticsService.instance.logSignUp(method: 'email');
  }

  Future<void> resetPassword(String email) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.flutterpos://reset-callback/',
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await AnalyticsService.instance.setUserId(user.id);
    }
    await AnalyticsService.instance.logLogin(method: 'google');
  }

  Future<void> signOut() async {
    try {
      await FCMService.instance.deleteTokenFromSupabase();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_store_id');
    await AnalyticsService.instance.setUserId(null);
    await Supabase.instance.client.auth.signOut();
    await GoogleSignIn().signOut();
  }

  Future<void> linkGoogle() async {
    final googleSignIn = GoogleSignIn(
      serverClientId:
          '49185547481-5oedne01p4or15n42svra2saiatmirck.apps.googleusercontent.com',
    );
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;
    final accessToken = googleAuth?.accessToken;
    final idToken = googleAuth?.idToken;

    if (idToken == null) {
      throw 'Menghubungkan Google dibatalkan atau gagal.';
    }

    await Supabase.instance.client.auth.linkIdentityWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<void> unlinkGoogle() async {
    final identities = await Supabase.instance.client.auth.getUserIdentities();
    final googleIdentity = identities.singleWhere((identity) => identity.provider == 'google');
    await Supabase.instance.client.auth.unlinkIdentity(googleIdentity);
  }
}

@riverpod
User? currentUser(CurrentUserRef ref) {
  ref.watch(authProvider); // Reactive to auth state changes
  return Supabase.instance.client.auth.currentUser;
}

@riverpod
Future<Map<String, dynamic>?> userProfile(UserProfileRef ref) async {
  ref.watch(authProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  
  try {
    final profile = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (profile != null) return profile;
  } catch (_) {}
  
  try {
    final userData = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (userData != null) return userData;
  } catch (_) {}
  
  return {
    'id': user.id,
    'email': user.email,
    'full_name': user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? user.email?.split('@')[0],
    'avatar_url': user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
  };
}
