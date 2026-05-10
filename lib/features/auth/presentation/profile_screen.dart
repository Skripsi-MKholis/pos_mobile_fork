import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/features/auth/providers/auth_provider.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Profil Saya',
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.w900),
        ),
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Warna.primary.withOpacity(0.3), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Warna.primary,
                        child: Text(
                          user?.email?[0].toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(TablerIcons.camera, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              ),
              const SizedBox(height: 24),
              Text(
                user?.email?.split('@')[0].toUpperCase() ?? 'USER',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
              ),
              Text(
                user?.email ?? '',
                style: theme.textTheme.muted,
              ),
              const SizedBox(height: 40),
              _buildInfoCard(
                theme,
                'Informasi Akun',
                [
                  _buildInfoRow(TablerIcons.mail, 'Email', user?.email ?? '-'),
                  _buildInfoRow(TablerIcons.shield_check, 'Role', (user?.appMetadata['role'] ?? 'User').toString().toUpperCase()),
                  _buildInfoRow(TablerIcons.calendar, 'Terdaftar Sejak', _formatDate(user?.createdAt)),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoCard(
                theme,
                'Keamanan',
                [
                  _buildActionRow(context, TablerIcons.lock, 'Ganti Kata Sandi', () {}),
                  _buildActionRow(context, TablerIcons.device_mobile, 'Perangkat Terhubung', () {}),
                ],
              ),
              const SizedBox(height: 40),
              ShadButton.outline(
                width: double.infinity,
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildInfoCard(ShadThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.black38,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black45),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      dense: true,
      leading: Icon(icon, size: 18, color: Colors.black),
      title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      trailing: const Icon(TablerIcons.chevron_right, size: 14, color: Colors.black26),
    );
  }
}
