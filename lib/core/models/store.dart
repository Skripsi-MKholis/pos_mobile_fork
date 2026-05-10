import 'package:isar/isar.dart';

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
  
  // Settings or other metadata as JSON string if needed
  String? metadata;

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
    this.metadata,
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
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
