import 'package:isar/isar.dart';
import 'dart:convert';

part 'store.g.dart';

@collection
class Store {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String supabaseId;

  late String name;
  String? address;
  String? phone;
  String? logoUrl;
  
  late String ownerId;
  String? inviteCode;
  String? province;
  String? city;

  // Settings or other metadata as JSON string
  String? settings;
  String? userRole;

  DateTime? updatedAt;

  Store({
    this.id = Isar.autoIncrement,
    required this.supabaseId,
    required this.name,
    this.address,
    this.phone,
    this.logoUrl,
    required this.ownerId,
    this.inviteCode,
    this.province,
    this.city,
    this.settings,
    this.userRole,
    this.updatedAt,
  });

  // Helper to map from Map
  static Store fromMap(Map<String, dynamic> map) {
    return Store(
      supabaseId: map['id'].toString(),
      name: map['name'] ?? '',
      address: map['address'],
      phone: map['phone'],
      logoUrl: map['logo_url'],
      ownerId: map['owner_id'] ?? '',
      inviteCode: map['invite_code'],
      province: map['province'],
      city: map['city'],
      settings: map['settings'] != null ? jsonEncode(map['settings']) : null,
      userRole: map['user_role'],
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': supabaseId,
      'name': name,
      'address': address,
      'phone': phone,
      'logo_url': logoUrl,
      'owner_id': ownerId,
      'invite_code': inviteCode,
      'province': province,
      'city': city,
      'settings': settings != null ? jsonDecode(settings!) : null,
      'user_role': userRole,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
