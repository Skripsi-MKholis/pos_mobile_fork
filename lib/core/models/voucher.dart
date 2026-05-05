class Voucher {
  final String id;
  final String code;
  final String type; // percentage, fixed
  final double value;
  final double minPurchase;
  final double? maxDiscount;

  Voucher({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minPurchase = 0,
    this.maxDiscount,
  });

  factory Voucher.fromMap(Map<String, dynamic> map) {
    return Voucher(
      id: map['id'],
      code: map['code'],
      type: map['type'],
      value: (map['value'] as num).toDouble(),
      minPurchase: (map['min_purchase'] as num?)?.toDouble() ?? 0,
      maxDiscount: (map['max_discount'] as num?)?.toDouble(),
    );
  }

  double calculateDiscount(double amount) {
    if (amount < minPurchase) return 0;
    
    double discount = 0;
    if (type == 'percentage') {
      discount = amount * (value / 100);
      if (maxDiscount != null && discount > maxDiscount!) {
        discount = maxDiscount!;
      }
    } else {
      discount = value;
    }
    
    return discount > amount ? amount : discount;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'value': value,
      'min_purchase': minPurchase,
      'max_discount': maxDiscount,
    };
  }
}
