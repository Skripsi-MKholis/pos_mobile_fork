import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: theme.colorScheme.mutedForeground),
          const SizedBox(height: 16),
          Text('Segera Hadir', style: theme.textTheme.h4),
          Text('Halaman riwayat transaksi sedang disiapkan.', style: theme.textTheme.muted),
        ],
      ),
    );
  }
}
