import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:tabler_icons/tabler_icons.dart';
import 'package:pos_mobile/Configuration/configuration.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

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
          'Manajemen Staf',
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(activeStoreProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 24),
                _buildInviteCodeCard(theme),
                const SizedBox(height: 32),
                _buildSearchAndAdd(theme),
                const SizedBox(height: 16),
                _buildStaffList(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manajemen Staf',
          style: theme.textTheme.h3.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Kelola karyawan dan hak akses mereka untuk toko Parzello Tech.',
          style: theme.textTheme.muted,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildInviteCodeCard(ShadThemeData theme) {
    final activeStore = ref.watch(activeStoreProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FFF0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Warna.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Warna.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Warna.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Warna.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  TablerIcons.ticket,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cepat & Mudah',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Berikan kode ini kepada staf agar mereka bisa bergabung sendiri.',
                      style: theme.textTheme.muted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          activeStore.when(
            data: (store) {
              final inviteCode = store?['invite_code'] ?? '------';
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.border.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Text(
                        inviteCode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Warna.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildCircleIconButton(TablerIcons.copy, () {
                    Clipboard.setData(ClipboardData(text: inviteCode));
                    ShadToaster.of(context).show(
                      const ShadToast(
                        title: Text('Berhasil'),
                        description: Text('Kode undangan berhasil disalin!'),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  _buildCircleIconButton(
                    TablerIcons.refresh,
                    () => _refreshInviteCode(store?['id']),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Gagal memuat kode: $err'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Future<void> _refreshInviteCode(dynamic storeId) async {
    if (storeId == null) return;

    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final newCode = List.generate(
      8,
      (index) => chars[Random().nextInt(chars.length)],
    ).join();

    try {
      await sb.Supabase.instance.client
          .from('stores')
          .update({'invite_code': newCode})
          .eq('id', storeId);

      ref.invalidate(activeStoreProvider);

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Berhasil'),
            description: Text('Kode undangan berhasil diperbarui!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Error'),
            description: Text('Gagal memperbarui kode: $e'),
          ),
        );
      }
    }
  }

  Widget _buildCircleIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: Colors.black87),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSearchAndAdd(ShadThemeData theme) {
    return Column(
      children: [
        ShadInput(
          controller: _searchController,
          placeholder: const Text('Cari nama atau email staf...'),
          leading: const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(TablerIcons.search, size: 18, color: Colors.black45),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ShadButton(
            backgroundColor: Warna.primary,
            hoverBackgroundColor: Warna.primary.withValues(alpha: 0.8),
            onPressed: () => _showAddStaffModal(theme),
            leading: const Icon(
              TablerIcons.plus,
              size: 18,
              color: Colors.black,
            ),
            child: const Text(
              'Tambah Staf Baru',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffList(ShadThemeData theme) {
    final staffListAsync = ref.watch(staffListProvider);

    return staffListAsync.when(
      data: (staffList) {
        if (staffList.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    TablerIcons.users,
                    size: 48,
                    color: theme.colorScheme.muted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada staf terdaftar.',
                    style: theme.textTheme.muted,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: staffList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final staff = staffList[index];
            return _buildStaffItem(theme, staff);
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Gagal memuat staf: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  void _showAddStaffModal(ShadThemeData theme) {
    final emailController = TextEditingController();
    String selectedRole = 'Karyawan';

    showShadDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return ShadDialog(
            title: const Text('Tambah Staf Baru'),
            description: const Text(
              'Masukkan alamat email pengguna yang sudah terdaftar di POS System.',
            ),
            child: Container(
              width: 400,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email Pengguna',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ShadInput(
                    controller: emailController,
                    placeholder: const Text('karyawan@example.com'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Role / Peran',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ShadSelect<String>(
                    placeholder: const Text('Pilih Role'),
                    initialValue: selectedRole,
                    options: [
                      ShadOption(
                        value: 'Karyawan',
                        child: const Text('Karyawan (Kasir)'),
                      ),
                      ShadOption(
                        value: 'Owner',
                        child: const Text('Owner (Pemilik)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => selectedRole = value);
                      }
                    },
                    selectedOptionBuilder: (context, value) => Text(
                      value == 'Karyawan'
                          ? 'Karyawan (Kasir)'
                          : 'Owner (Pemilik)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ShadButton.outline(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              ShadButton(
                backgroundColor: Warna.primary,
                hoverBackgroundColor: Warna.primary.withValues(alpha: 0.8),
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) return;

                  await _addStaff(email, selectedRole);
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text(
                  'Tambahkan Staf',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addStaff(String email, String role) async {
    final supabase = sb.Supabase.instance.client;
    final activeStore = await ref.read(activeStoreProvider.future);

    if (activeStore == null) return;

    try {
      // 1. Find user by email
      final userResponse = await supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (userResponse == null) {
        if (mounted) {
          ShadToaster.of(context).show(
            ShadToast.destructive(
              title: const Text('Error'),
              description: Text(
                'Pengguna dengan email $email belum terdaftar di sistem.',
              ),
            ),
          );
        }
        return;
      }

      final userId = userResponse['id'];

      // 2. Check if already a member
      final memberCheck = await supabase
          .from('store_members')
          .select()
          .eq('store_id', activeStore['id'])
          .eq('user_id', userId)
          .maybeSingle();

      if (memberCheck != null) {
        if (mounted) {
          ShadToaster.of(context).show(
            ShadToast.destructive(
              title: const Text('Error'),
              description: const Text(
                'Pengguna sudah menjadi staf di toko ini.',
              ),
            ),
          );
        }
        return;
      }

      // 3. Add to store_members
      await supabase.from('store_members').insert({
        'store_id': activeStore['id'],
        'user_id': userId,
        'role': role,
        'status': 'active',
      });

      ref.invalidate(staffListProvider);

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Berhasil'),
            description: Text('Staf baru berhasil ditambahkan!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Error'),
            description: Text('Gagal menambahkan staf: $e'),
          ),
        );
      }
    }
  }

  Future<void> _updateStaff(
    String memberId,
    String role,
    String status,
  ) async {
    final supabase = sb.Supabase.instance.client;

    try {
      await supabase.from('store_members').update({
        'role': role,
        'status': status,
      }).eq('id', memberId);

      ref.invalidate(staffListProvider);

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Berhasil'),
            description: Text('Data staf berhasil diperbarui!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Error'),
            description: Text('Gagal memperbarui staf: $e'),
          ),
        );
      }
    }
  }

  Future<void> _deleteStaff(String memberId) async {
    final supabase = sb.Supabase.instance.client;

    try {
      await supabase.from('store_members').delete().eq('id', memberId);

      ref.invalidate(staffListProvider);

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Berhasil'),
            description: Text('Staf berhasil dihapus dari toko!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Error'),
            description: Text('Gagal menghapus staf: $e'),
          ),
        );
      }
    }
  }

  void _showEditStaffModal(Map<String, dynamic> staff) {
    String selectedRole = staff['role'];
    String selectedStatus = staff['status'];

    showShadDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return ShadDialog(
            title: const Text('Edit Data Staf'),
            description: Text('Ubah peran atau status untuk ${staff['name']}.'),
            child: Container(
              width: 400,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Role / Peran',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ShadSelect<String>(
                    placeholder: const Text('Pilih Role'),
                    initialValue: selectedRole,
                    options: [
                      ShadOption(
                        value: 'Karyawan',
                        child: const Text('Karyawan (Kasir)'),
                      ),
                      ShadOption(
                        value: 'Owner',
                        child: const Text('Owner (Pemilik)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => selectedRole = value);
                      }
                    },
                    selectedOptionBuilder: (context, value) => Text(
                      value == 'Karyawan'
                          ? 'Karyawan (Kasir)'
                          : 'Owner (Pemilik)',
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ShadSelect<String>(
                    placeholder: const Text('Pilih Status'),
                    initialValue: selectedStatus,
                    options: [
                      ShadOption(
                        value: 'active',
                        child: const Text('Aktif'),
                      ),
                      ShadOption(
                        value: 'pending',
                        child: const Text('Pending'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => selectedStatus = value);
                      }
                    },
                    selectedOptionBuilder: (context, value) => Text(
                      value == 'active' ? 'Aktif' : 'Pending',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ShadButton.outline(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              ShadButton(
                backgroundColor: Warna.primary,
                hoverBackgroundColor: Warna.primary.withValues(alpha: 0.8),
                onPressed: () async {
                  await _updateStaff(
                    staff['id'],
                    selectedRole,
                    selectedStatus,
                  );
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteStaffDialog(Map<String, dynamic> staff) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Hapus Staf'),
        description: Text(
          'Apakah Anda yakin ingin menghapus ${staff['name']} dari toko? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ShadButton.destructive(
            onPressed: () async {
              await _deleteStaff(staff['id']);
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffItem(ShadThemeData theme, Map<String, dynamic> staff) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Warna.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  TablerIcons.user,
                  color: Warna.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      staff['email']!,
                      style: theme.textTheme.muted.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildRoleBadge(staff['role']!),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Warna.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    staff['status']!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  ShadButton.ghost(
                    size: ShadButtonSize.sm,
                    onPressed: () => _showEditStaffModal(staff),
                    leading: const Icon(
                      TablerIcons.edit,
                      size: 18,
                      color: Warna.primary,
                    ),
                    child: const Text('Edit'),
                  ),
                  const SizedBox(width: 4),
                  if (staff['user_id'] !=
                      sb.Supabase.instance.client.auth.currentUser?.id)
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      onPressed: () => _showDeleteStaffDialog(staff),
                      leading: const Icon(
                        TablerIcons.trash,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final isOwner = role == 'Owner';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOwner ? const Color(0xFFE0E7FF) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOwner ? TablerIcons.shield : TablerIcons.shield_check,
            size: 14,
            color: isOwner ? const Color(0xFF4338CA) : const Color(0xFF15803D),
          ),
          const SizedBox(width: 4),
          Text(
            role,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isOwner
                  ? const Color(0xFF4338CA)
                  : const Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }
}

final staffListProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final activeStore = await ref.watch(activeStoreProvider.future);
  if (activeStore == null) return [];

  final supabase = sb.Supabase.instance.client;
  final response = await supabase
      .from('store_members')
      .select('*, users!inner(*)')
      .eq('store_id', activeStore['id']);

  return (response as List).map((item) {
    final user = item['users'] as Map<String, dynamic>;
    return {
      'id': item['id'],
      'user_id': item['user_id'],
      'name': user['full_name'] ?? 'No Name',
      'email': user['email'] ?? 'No Email',
      'role': item['role'] ?? 'Karyawan',
      'status': item['status'] ?? 'active',
      'display_status': item['status'] == 'active' ? 'Aktif' : 'Pending',
    };
  }).toList();
});

