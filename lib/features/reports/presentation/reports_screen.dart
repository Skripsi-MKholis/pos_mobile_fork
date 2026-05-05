import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(TablerIcons.chart_dots, size: 64, color: theme.colorScheme.mutedForeground),
          const SizedBox(height: 16),
          Text('Laporan & Analitik', style: theme.textTheme.h4),
          Text('Fitur ini sedang dalam pengembangan.', style: theme.textTheme.muted),
        ],
      ),
    );
  }
}
