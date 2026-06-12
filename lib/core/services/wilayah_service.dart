import 'dart:convert';
import 'package:http/http.dart' as http;

class WilayahService {
  static final WilayahService instance = WilayahService._();
  WilayahService._();

  final Map<String, List<Map<String, dynamic>>> _cache = {};

  Future<List<Map<String, dynamic>>> getProvinces() async {
    const key = '__provinces__';
    if (_cache.containsKey(key)) return _cache[key]!;

    final response = await http
        .get(Uri.parse('https://wilayah.id/api/provinces.json'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) throw 'Gagal memuat data provinsi';

    final decoded = json.decode(response.body);
    final list = List<Map<String, dynamic>>.from(
      (decoded['data'] as List).map((e) => {
        'code': e['code'].toString(),
        'name': e['name'].toString(),
      }),
    );
    _cache[key] = list;
    return list;
  }

  Future<List<Map<String, dynamic>>> getCities(String provinceCode) async {
    final key = '__cities__$provinceCode';
    if (_cache.containsKey(key)) return _cache[key]!;

    final response = await http
        .get(Uri.parse('https://wilayah.id/api/regencies/$provinceCode.json'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) throw 'Gagal memuat data kota/kabupaten';

    final decoded = json.decode(response.body);
    final list = List<Map<String, dynamic>>.from(
      (decoded['data'] as List).map((e) => {
        'code': e['code'].toString(),
        'name': e['name'].toString(),
      }),
    );
    _cache[key] = list;
    return list;
  }

  String toTitleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }
}
