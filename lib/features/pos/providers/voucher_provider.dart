import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_mobile/core/models/voucher.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';

part 'voucher_provider.g.dart';

@riverpod
class VoucherNotifier extends _$VoucherNotifier {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<Voucher>> build() async {
    return [];
  }

  Future<Voucher?> validateVoucher(String code) async {
    final activeStore = ref.read(activeStoreProvider).value;
    final storeId = activeStore?['id'];

    if (storeId == null) return null;

    try {
      final response = await _supabase
          .from('vouchers')
          .select()
          .eq('store_id', storeId)
          .eq('code', code)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      final voucher = Voucher.fromMap(response);

      if (response['expires_at'] != null) {
        final expiry = DateTime.parse(response['expires_at']);
        if (expiry.isBefore(DateTime.now())) return null;
      }

      return voucher;
    } catch (e) {
      return null;
    }
  }
}
