import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';
import 'package:pos_mobile/core/providers/locale_provider.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeNotifierProvider);
    final isIndonesian = currentLocale.languageCode == 'id';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isIndonesian ? 'Pengaturan Aplikasi' : 'App Settings',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section: Preferensi Sistem & Aplikasi
                _buildSection(
                  theme,
                  title: isIndonesian ? 'PREFERENSI APLIKASI' : 'APP PREFERENCES',
                  children: [
                    _buildTile(
                      theme,
                      icon: TablerIcons.language,
                      title: l10n.language,
                      trailingText: l10n.languageName,
                      subtitle: isIndonesian
                          ? 'Pilih bahasa antarmuka aplikasi'
                          : 'Select application interface language',
                      onTap: () => _showLanguageSelector(context, ref, currentLocale),
                    ),
                    _buildTile(
                      theme,
                      icon: TablerIcons.refresh,
                      title: l10n.dataSynchronization,
                      subtitle: isIndonesian
                          ? 'Status antrean & sinkronisasi offline'
                          : 'Offline queue status & data sync',
                      onTap: () => context.push('/sync-monitoring'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // App Version Info
                Center(
                  child: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final appVersion = snapshot.data?.version ?? '';
                      final buildNumber = snapshot.data?.buildNumber ?? '';
                      return Text(
                        'Zello POS • ${l10n.version} $appVersion ($buildNumber)',
                        style: theme.textTheme.muted.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    ShadThemeData theme, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.muted.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 10.5,
              letterSpacing: 1.5,
              color: theme.colorScheme.mutedForeground.withValues(alpha: 0.8),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.border.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    indent: 52,
                    endIndent: 16,
                    color: theme.colorScheme.border.withValues(alpha: 0.3),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTile(
    ShadThemeData theme, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: (color?.withValues(alpha: 0.1) ??
              theme.colorScheme.muted.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: color ?? Colors.black,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: color ?? Colors.black,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.muted.copyWith(fontSize: 11.5),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: theme.textTheme.muted.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Icon(
            TablerIcons.chevron_right,
            size: 16,
            color: color?.withValues(alpha: 0.5) ?? Colors.black26,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Future<void> _showLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);

    await showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(l10n.selectLanguage),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageOption(
                  context: context,
                  title: l10n.indonesian,
                  isSelected: currentLocale.languageCode == 'id',
                  theme: theme,
                  onTap: () {
                    ref
                        .read(localeNotifierProvider.notifier)
                        .changeLocale('id');
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 10),
                _buildLanguageOption(
                  context: context,
                  title: l10n.english,
                  isSelected: currentLocale.languageCode == 'en',
                  theme: theme,
                  onTap: () {
                    ref
                        .read(localeNotifierProvider.notifier)
                        .changeLocale('en');
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required ShadThemeData theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.border.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.black : Colors.black87,
              ),
            ),
            if (isSelected)
              Icon(
                TablerIcons.check,
                color: theme.colorScheme.primary,
                size: 18,
              )
            else
              const SizedBox(width: 18, height: 18),
          ],
        ),
      ),
    );
  }
}
