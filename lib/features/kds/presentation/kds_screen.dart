import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class KDSScreen extends StatelessWidget {
  const KDSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Monitor Dapur (KDS)',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.muted.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(TablerIcons.chevron_left, size: 20),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        toolbarHeight: 80,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  TablerIcons.device_desktop_analytics,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Segera Hadir!',
                style: theme.textTheme.h2.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Fitur Kitchen Display System (KDS) sedang dalam tahap pengembangan. Nantikan pembaruan selanjutnya.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.muted.copyWith(
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              ShadButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                },
                child: const Text('Kembali ke Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
