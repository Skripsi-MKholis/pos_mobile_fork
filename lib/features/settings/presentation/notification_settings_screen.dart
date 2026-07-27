import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_mobile/core/services/local_notification_service.dart';
import 'package:pos_mobile/core/services/notification_scheduler_service.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/features/reports/data/forecast_notification_service.dart';
import 'package:pos_mobile/l10n/app_localizations.dart';

/// Layar pengaturan notifikasi & pengingat jam kerja.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _loading = true;
  bool _enabled = NotificationSchedulerService.defaultEnabled;
  int _startMinutes = NotificationSchedulerService.defaultStartMinutes;
  int _endMinutes = NotificationSchedulerService.defaultEndMinutes;
  int _intervalHours = NotificationSchedulerService.defaultIntervalHours;

  /// Sakelar terpisah untuk notifikasi prediksi esok hari (§8.7) — pengguna
  /// bisa mematikannya tanpa ikut mematikan pengingat jam kerja.
  bool _forecastEnabled = ForecastNotificationService.defaultEnabled;

  static const List<int> _intervalOptions = [2, 3, 4, 6];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool(NotificationSchedulerService.keyEnabled) ??
          NotificationSchedulerService.defaultEnabled;
      _startMinutes =
          prefs.getInt(NotificationSchedulerService.keyStartMinutes) ??
              NotificationSchedulerService.defaultStartMinutes;
      _endMinutes = prefs.getInt(NotificationSchedulerService.keyEndMinutes) ??
          NotificationSchedulerService.defaultEndMinutes;
      _intervalHours =
          prefs.getInt(NotificationSchedulerService.keyIntervalHours) ??
              NotificationSchedulerService.defaultIntervalHours;
      _forecastEnabled = prefs.getBool(ForecastNotificationService.keyEnabled) ??
          ForecastNotificationService.defaultEnabled;
      _loading = false;
    });
  }

  Future<void> _saveForecastPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ForecastNotificationService.keyEnabled, value);

    final storeId = ref.read(activeStoreProvider).value?['id']?.toString();
    if (!value || storeId == null) {
      await ForecastNotificationService.instance.cancel();
    } else {
      await LocalNotificationService.instance.requestPermissions();
      await ForecastNotificationService.instance.syncFromCache(storeId);
    }

    if (mounted) {
      mySnackBar(
        context: context,
        text: value
            ? 'Notifikasi prediksi diaktifkan.'
            : 'Notifikasi prediksi dimatikan.',
        status: ToastStatus.success,
      );
    }
  }

  Future<void> _savePrefsAndReschedule() async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationSchedulerService.keyEnabled, _enabled);
    await prefs.setInt(
        NotificationSchedulerService.keyStartMinutes, _startMinutes);
    await prefs.setInt(NotificationSchedulerService.keyEndMinutes, _endMinutes);
    await prefs.setInt(
        NotificationSchedulerService.keyIntervalHours, _intervalHours);

    await NotificationSchedulerService.instance.syncFromPrefs();

    if (mounted) {
      mySnackBar(
        context: context,
        text: l10n.reminderScheduleUpdated,
        status: ToastStatus.success,
      );
    }
  }

  String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime({required bool isStart}) async {
    final l10n = AppLocalizations.of(context)!;
    final current = isStart ? _startMinutes : _endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;

    final newMinutes = picked.hour * 60 + picked.minute;
    if (isStart && newMinutes >= _endMinutes ||
        !isStart && newMinutes <= _startMinutes) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: l10n.invalidWorkHourRange,
          status: ToastStatus.error,
        );
      }
      return;
    }

    setState(() {
      if (isStart) {
        _startMinutes = newMinutes;
      } else {
        _endMinutes = newMinutes;
      }
    });
    await _savePrefsAndReschedule();
  }

  Future<void> _sendTestNotification() async {
    final l10n = AppLocalizations.of(context)!;
    await LocalNotificationService.instance.requestPermissions();
    await LocalNotificationService.instance.showTestNotification(
      title: l10n.testNotificationTitle,
      body: l10n.testNotificationBody,
    );
    if (mounted) {
      mySnackBar(
        context: context,
        text: l10n.testNotificationSent,
        status: ToastStatus.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.notificationSettings,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Toggle utama =====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Warna.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Warna.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Warna.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(TablerIcons.bell_ringing,
                              color: Colors.black, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.workReminderTitle,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.workReminderDesc,
                                style: theme.textTheme.muted
                                    .copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ShadSwitch(
                          value: _enabled,
                          onChanged: (v) async {
                            setState(() => _enabled = v);
                            if (v) {
                              await LocalNotificationService.instance
                                  .requestPermissions();
                            }
                            await _savePrefsAndReschedule();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== Notifikasi prediksi (§8.7) =====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Warna.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(TablerIcons.brain,
                              color: Colors.black, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notifikasi Prediksi',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ringkasan prakiraan penjualan & stok untuk '
                                'besok, dikirim pukul '
                                '${ForecastNotificationService.defaultHour}.00 '
                                'dari data yang tersimpan di perangkat.',
                                style: theme.textTheme.muted
                                    .copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ShadSwitch(
                          value: _forecastEnabled,
                          onChanged: (v) async {
                            setState(() => _forecastEnabled = v);
                            await _saveForecastPref(v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ===== Jam kerja =====
                  Opacity(
                    opacity: _enabled ? 1 : 0.4,
                    child: IgnorePointer(
                      ignoring: !_enabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeCard(
                                  theme: theme,
                                  label: l10n.workStartTime,
                                  value: _formatMinutes(_startMinutes),
                                  icon: TablerIcons.sunrise,
                                  onTap: () => _pickTime(isStart: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTimeCard(
                                  theme: theme,
                                  label: l10n.workEndTime,
                                  value: _formatMinutes(_endMinutes),
                                  icon: TablerIcons.sunset,
                                  onTap: () => _pickTime(isStart: false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ===== Interval =====
                          Text(
                            l10n.reminderInterval.toUpperCase(),
                            style: theme.textTheme.muted.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _intervalOptions.map((h) {
                              final selected = _intervalHours == h;
                              return ChoiceChip(
                                label: Text(l10n.everyXHours(h)),
                                selected: selected,
                                selectedColor: Warna.primary,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? Colors.black
                                      : Colors.black54,
                                ),
                                onSelected: (_) async {
                                  setState(() => _intervalHours = h);
                                  await _savePrefsAndReschedule();
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ===== Aksi =====
                  ShadButton(
                    width: double.infinity,
                    onPressed: _sendTestNotification,
                    leading: const Icon(TablerIcons.bell_check, size: 16),
                    child: Text(l10n.testNotification),
                  ),
                  const SizedBox(height: 12),
                  ShadButton.outline(
                    width: double.infinity,
                    onPressed: () => ph.openAppSettings(),
                    leading: const Icon(TablerIcons.settings, size: 16),
                    child: Text(l10n.openOsNotificationSettings),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeCard({
    required ShadThemeData theme,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.border.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.black54),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.muted.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
