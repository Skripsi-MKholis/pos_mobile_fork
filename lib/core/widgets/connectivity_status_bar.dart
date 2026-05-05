import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mobile/core/providers/connectivity_provider.dart';
import 'package:pos_mobile/core/providers/sync_provider.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ConnectivityStatusBar extends ConsumerWidget {
  const ConnectivityStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch sync notifier to keep it alive
    ref.watch(syncNotifierProvider);
    
    final status = ref.watch(connectivityNotifierProvider);
    final theme = ShadTheme.of(context);

    return status.when(
      data: (s) {
        if (s == ConnectivityStatus.online) return const SizedBox.shrink();
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          color: Colors.orange.withValues(alpha: 0.9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(TablerIcons.wifi_off, size: 14, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Mode Offline - Data akan disimpan secara lokal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
