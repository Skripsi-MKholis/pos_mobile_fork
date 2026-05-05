class TableModel {
  final String id;
  final String storeId;
  final String name;
  final String status; // available, occupied, cleaning, reserved
  final int capacity;

  TableModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.status,
    this.capacity = 2,
  });

  factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(
      id: map['id'],
      storeId: map['store_id'],
      name: map['name'],
      status: map['status'] ?? 'available',
      capacity: map['capacity'] ?? 2,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_id': storeId,
      'name': name,
      'status': status,
      'capacity': capacity,
    };
  }
}
