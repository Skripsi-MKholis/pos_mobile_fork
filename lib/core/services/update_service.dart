import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  bool _isChecking = false;

  /// Memeriksa ketersediaan update dan menjalankan update native Google Play.
  /// 
  /// Dibungkus try-catch agar jika gagal saat running local (tidak terkoneksi Play Store)
  /// aplikasi tidak mengalami crash.
  Future<void> checkForUpdate(BuildContext context) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      debugPrint('Menghubungi Google Play Store untuk memeriksa update...');
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        debugPrint('Update tersedia!');
        
        // 1. Coba update segera (Immediate) jika diizinkan (Update Kritis)
        if (info.immediateUpdateAllowed) {
          debugPrint('Menjalankan Immediate Update...');
          await InAppUpdate.performImmediateUpdate();
        } 
        // 2. Coba update fleksibel jika diizinkan (Background download)
        else if (info.flexibleUpdateAllowed) {
          debugPrint('Menjalankan Flexible Update...');
          await InAppUpdate.startFlexibleUpdate();
          
          if (context.mounted) {
            _showUpdateCompletedBar(context);
          }
        }
      } else {
        debugPrint('Aplikasi sudah menggunakan versi terbaru.');
      }
    } catch (e) {
      // Ditangkap agar tidak crash saat pengujian lokal (emulator/non-release build)
      debugPrint('Info Update: Gagal memeriksa pembaruan Play Store (Umum terjadi di mode debug): $e');
    } finally {
      _isChecking = false;
    }
  }

  /// Menampilkan snackbar untuk mengonfirmasi pemasangan update setelah selesai diunduh.
  void _showUpdateCompletedBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Versi terbaru berhasil diunduh. Silakan terapkan untuk me-restart aplikasi.',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(days: 365), // Tetap tampil sampai diklik
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16), // Memberi ruang di atas navbar melayang
        action: SnackBarAction(
          label: 'TERAPKAN',
          textColor: const Color(0xff1AC966), // Warna hijau sukses
          onPressed: () async {
            try {
              await InAppUpdate.completeFlexibleUpdate();
            } catch (e) {
              debugPrint('Gagal menyelesaikan update fleksibel: $e');
            }
          },
        ),
      ),
    );
  }
}
