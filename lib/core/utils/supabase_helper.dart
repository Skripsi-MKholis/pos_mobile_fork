import 'package:supabase_flutter/supabase_flutter.dart';

extension SupabaseClientExtension on SupabaseClient {
  /// Ensures that the current session is valid and not expired.
  /// If it expires in less than 5 minutes (300 seconds) or is already expired,
  /// it will pre-emptively attempt to refresh the session to account for clock skew.
  Future<void> ensureValidSession() async {
    final session = auth.currentSession;
    if (session != null) {
      final expiresAtSecs = session.expiresAt;
      final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // Generous buffer of 5 minutes (300 seconds) to account for clock skew
      const buffer = 300;
      if (expiresAtSecs != null && (expiresAtSecs - nowSecs < buffer)) {
        try {
          print('DEBUG: [SupabaseHelper] Session is near expiration or expired (expires in ${expiresAtSecs - nowSecs}s, buffer: ${buffer}s). Refreshing...');
          await auth.refreshSession();
          print('DEBUG: [SupabaseHelper] Session refreshed successfully.');
        } catch (e) {
          print('DEBUG: [SupabaseHelper] Error refreshing session: $e');
        }
      }
    }
  }

  /// Executes a Supabase database call with automatic JWT refresh and retry if a "JWT expired" error is encountered.
  Future<T> retryWithFreshSession<T>(Future<T> Function() queryBlock) async {
    try {
      // Pre-emptively ensure session is valid
      await ensureValidSession();
      return await queryBlock();
    } catch (e) {
      if (e is PostgrestException && (e.message.contains('JWT expired') || e.code == 'PGRST303' || e.message.contains('PGRST303'))) {
        print('DEBUG: [SupabaseHelper] JWT expired error caught. Forcing session refresh and retrying query...');
        try {
          await auth.refreshSession();
          // Retry the query block once
          return await queryBlock();
        } catch (refreshErr) {
          print('DEBUG: [SupabaseHelper] Session refresh failed on retry: $refreshErr');
          rethrow;
        }
      }
      rethrow;
    }
  }
}
