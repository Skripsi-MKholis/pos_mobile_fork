import 'package:image_picker/image_picker.dart';

/// Helper terpusat untuk konfigurasi pemilihan dan kompresi gambar.
///
/// Menggunakan native compression dari `image_picker`:
/// - `imageQuality: 75`: Mengurangi ukuran berkas secara signifikan (bisa turun 70-85% dari ukuran asli kamera)
///   tanpa kehilangan detail penting / gambar tetap tajam & jernih.
/// - `maxWidth` & `maxHeight`: Membatasi resolusi agar tidak terlalu raksasa (misal 4000x3000px dari kamera ponsel)
///   yang membuat upload lambat dan boros kuota penyimpanan.
class AppImagePicker {
  AppImagePicker._();

  static final ImagePicker _picker = ImagePicker();

  /// Pick & kompres gambar untuk Logo Toko (persegi / tajam, max 800x800, quality 80)
  static Future<XFile?> pickStoreLogo(ImageSource source) async {
    return _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
  }

  /// Pick & kompres gambar untuk Foto Profil Pengguna (max 800x800, quality 80)
  static Future<XFile?> pickAvatar(ImageSource source) async {
    return _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
  }

  /// Pick & kompres gambar untuk Foto Produk (max 1024x1024, quality 75)
  static Future<XFile?> pickProductImage({ImageSource source = ImageSource.gallery}) async {
    return _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
  }
}
