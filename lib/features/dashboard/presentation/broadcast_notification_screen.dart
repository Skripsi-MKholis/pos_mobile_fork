import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/features/dashboard/providers/notification_provider.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:pos_mobile/Configuration/components.dart';

class BroadcastNotificationScreen extends ConsumerStatefulWidget {
  const BroadcastNotificationScreen({super.key});

  @override
  ConsumerState<BroadcastNotificationScreen> createState() =>
      _BroadcastNotificationScreenState();
}

class _BroadcastNotificationScreenState
    extends ConsumerState<BroadcastNotificationScreen> {
  final _formKey = GlobalKey<ShadFormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'announcement';
  bool _isSending = false;

  // Real-time values for live preview
  String _liveTitle = '';
  String _liveMessage = '';

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      setState(() {
        _liveTitle = _titleController.text;
      });
    });
    _messageController.addListener(() {
      setState(() {
        _liveMessage = _messageController.text;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'danger':
        return TablerIcons.alert_circle;
      case 'warning':
        return TablerIcons.alert_triangle;
      case 'success':
        return TablerIcons.circle_check;
      case 'announcement':
        return TablerIcons.speakerphone;
      case 'promo':
        return TablerIcons.ticket;
      case 'technical':
        return TablerIcons.tool;
      default:
        return TablerIcons.info_circle;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'danger':
        return Warna.destructive;
      case 'warning':
        return Colors.amber.shade800;
      case 'success':
        return Colors.green;
      case 'announcement':
        return Colors.blue;
      case 'promo':
        return Colors.indigo;
      case 'technical':
        return Colors.orange;
      default:
        return Colors.lightGreen;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'danger':
        return 'Danger';
      case 'warning':
        return 'Warning';
      case 'success':
        return 'Success';
      case 'announcement':
        return 'Pengumuman';
      case 'promo':
        return 'Promo';
      case 'technical':
        return 'Teknis';
      default:
        return 'Info Umum';
    }
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    setState(() => _isSending = true);

    try {
      final title = _titleController.text.trim();
      final message = _messageController.text.trim();

      await ref
          .read(notificationNotifierProvider.notifier)
          .sendBroadcast(title: title, message: message, type: _selectedType);

      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Notifikasi broadcast berhasil dikirim ke semua staf!',
          status: ToastStatus.success,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Error: $e',
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final previewColor = _getTypeColor(_selectedType);
    final previewIcon = _getTypeIcon(_selectedType);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Kirim Broadcast',
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ShadForm(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Text(
                  'Broadcast Notifikasi',
                  style: theme.textTheme.h3.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kirim notifikasi real-time yang akan langsung muncul di perangkat seluruh staf toko.',
                  style: theme.textTheme.muted,
                ),
                const SizedBox(height: 28),

                // Live Preview Card Section Label
                Row(
                  children: [
                    const Icon(TablerIcons.eye, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'PRATINJAU NOTIFIKASI (LIVE PREVIEW)',
                      style: theme.textTheme.muted.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Live Preview Card Box
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: previewColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: previewColor.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      color: previewColor.withValues(alpha: 0.03),
                      padding: const EdgeInsets.all(18.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type Icon
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: previewColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              previewIcon,
                              color: previewColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Content Preview
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _liveTitle.isEmpty
                                            ? 'Judul Notifikasi Anda'
                                            : _liveTitle,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: _liveTitle.isEmpty
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Live dot indicator
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: previewColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _liveMessage.isEmpty
                                      ? 'Isi pesan broadcast yang akan Anda kirim ke seluruh staf toko akan muncul di sini...'
                                      : _liveMessage,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _liveMessage.isEmpty
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade700,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Baru Saja',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: previewColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _getTypeLabel(_selectedType),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: previewColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 36),

                // Form Input: Notification Type
                const Text(
                  'Tipe Pemberitahuan',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ShadSelect<String>(
                  placeholder: const Text('Pilih Tipe Notifikasi'),
                  initialValue: _selectedType,
                  options: [
                    ShadOption(
                      value: 'announcement',
                      child: Row(
                        children: [
                          Icon(
                            TablerIcons.speakerphone,
                            color: Colors.blue,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Text('Pengumuman'),
                        ],
                      ),
                    ),
                    ShadOption(
                      value: 'info',
                      child: Row(
                        children: [
                          Icon(
                            TablerIcons.info_circle,
                            color: Colors.lightGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Text('Info Umum'),
                        ],
                      ),
                    ),
                    ShadOption(
                      value: 'promo',
                      child: Row(
                        children: [
                          Icon(
                            TablerIcons.ticket,
                            color: Colors.indigo,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Text('Promo'),
                        ],
                      ),
                    ),
                    ShadOption(
                      value: 'technical',
                      child: Row(
                        children: [
                          Icon(
                            TablerIcons.tool,
                            color: Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Text('Teknis'),
                        ],
                      ),
                    ),
                    ShadOption(
                      value: 'danger',
                      child: Row(
                        children: [
                          Icon(
                            TablerIcons.alert_circle,
                            color: Warna.destructive,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Text('Danger'),
                        ],
                      ),
                    ),
                    ShadOption(
                      value: 'warning',
                      child: Row(
                        children: [
                          Icon(
                            TablerIcons.alert_triangle,
                            color: Colors.amber.shade800,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Text('Warning'),
                        ],
                      ),
                    ),
                    ShadOption(
                      value: 'success',
                      child: Row(
                        children: [
                          Icon(
                            TablerIcons.circle_check,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Text('Success'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                  selectedOptionBuilder: (context, value) {
                    final color = _getTypeColor(value);
                    final icon = _getTypeIcon(value);
                    final label = _getTypeLabel(value);
                    return Row(
                      children: [
                        Icon(icon, color: color, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Form Input: Title
                ShadInputFormField(
                  id: 'title',
                  controller: _titleController,
                  label: const Text('Judul Notifikasi'),
                  placeholder: const Text('Masukkan judul pemberitahuan'),
                  validator: (v) {
                    if (v.trim().isEmpty) return 'Judul wajib diisi';
                    if (v.trim().length < 3)
                      return 'Judul terlalu pendek (minimal 3 karakter)';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Form Input: Message
                ShadInputFormField(
                  id: 'message',
                  controller: _messageController,
                  label: const Text('Pesan / Isi Notifikasi'),
                  placeholder: const Text(
                    'Ketik pesan yang ingin Anda sampaikan...',
                  ),
                  maxLines: 4,
                  validator: (v) {
                    if (v.trim().isEmpty) return 'Pesan wajib diisi';
                    if (v.trim().length < 5)
                      return 'Pesan terlalu pendek (minimal 5 karakter)';
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    backgroundColor: Warna.primary,
                    hoverBackgroundColor: Warna.primary.withValues(alpha: 0.8),
                    onPressed: _isSending ? null : _handleSend,
                    leading: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(
                            TablerIcons.speakerphone,
                            color: Colors.black,
                            size: 20,
                          ),
                    child: Text(
                      _isSending
                          ? 'Mengirim Broadcast...'
                          : 'Kirim Broadcast Sekarang',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
