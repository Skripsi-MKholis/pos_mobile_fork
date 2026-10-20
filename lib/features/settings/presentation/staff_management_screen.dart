import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:pos_mobile/core/guards/feature_guard.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = 'all'; // 'all', 'owner', 'karyawan'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final canAccess =
        ref.watch(canAccessFeatureProvider(AppFeature.staffManagement));
    final isLocked = !canAccess;

    final activeStoreAsync = ref.watch(activeStoreProvider);
    final activeStore = activeStoreAsync.value;

    final currentUser = sb.Supabase.instance.client.auth.currentUser;
    final userRole =
        activeStore?['user_role']?.toString().toLowerCase() ?? 'karyawan';
    final isOwner = userRole == 'owner' ||
        activeStore?['owner_id'] == currentUser?.id ||
        currentUser?.appMetadata['role'] == 'admin';

    final storeName = activeStore?['name']?.toString() ?? 'Toko';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Staf & Tim Toko',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              storeName,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isOwner
                  ? Warna.primary.withValues(alpha: 0.15)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOwner
                    ? Warna.primary.withValues(alpha: 0.4)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOwner ? TablerIcons.shield_check : TablerIcons.user_check,
                  size: 13,
                  color: isOwner ? const Color(0xFF15803D) : const Color(0xFF475569),
                ),
                const SizedBox(width: 4),
                Text(
                  isOwner ? 'Pemilik Toko' : 'Akses Terbatas',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        isOwner ? const Color(0xFF15803D) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: Warna.primary,
            onRefresh: isLocked
                ? () async {}
                : () async {
                    ref.invalidate(activeStoreProvider);
                    ref.invalidate(staffListProvider);
                  },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 18.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isOwner) _buildStaffReadOnlyNotice(theme),
                    if (isOwner) ...[
                      _buildInviteCodeCard(theme, activeStore),
                      const SizedBox(height: 20),
                    ],
                    _buildOverviewStats(theme),
                    const SizedBox(height: 20),
                    _buildSearchBar(theme),
                    const SizedBox(height: 12),
                    _buildRoleFilterChips(),
                    const SizedBox(height: 16),
                    if (isOwner) ...[
                      _buildAddStaffButton(theme),
                      const SizedBox(height: 16),
                    ],
                    _buildStaffList(theme, isOwner, currentUser?.id, activeStore),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (isLocked) _buildLockOverlay(theme),
        ],
      ),
    );
  }

  /// Banner informasi untuk Staf/Karyawan bahwa mode ini Read-Only
  Widget _buildStaffReadOnlyNotice(ShadThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: const Icon(
              TablerIcons.info_circle,
              color: Color(0xFF475569),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Tinjau Staf',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Anda memiliki akses untuk melihat rekan kerja di toko ini. Penambahan atau pengubahan wewenang hanya dapat dilakukan oleh Pemilik (Owner).',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ringkasan jumlah anggota tim & kasir
  Widget _buildOverviewStats(ShadThemeData theme) {
    final staffListAsync = ref.watch(staffListProvider);

    return staffListAsync.maybeWhen(
      data: (list) {
        final total = list.length;
        final totalOwner = list.where((s) => s['role'] == 'Owner').length;
        final totalStaff = list.where((s) => s['role'] != 'Owner').length;

        return Row(
          children: [
            Expanded(
              child: _buildMiniStat(
                label: 'Total Anggota',
                value: '$total',
                icon: TablerIcons.users,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStat(
                label: 'Kasir / Staf',
                value: '$totalStaff',
                icon: TablerIcons.user_check,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMiniStat(
                label: 'Pemilik (Owner)',
                value: '$totalOwner',
                icon: TablerIcons.crown,
                color: const Color(0xFFD97706),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
              Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Kartu Kode Undangan yang hanya muncul untuk Owner
  Widget _buildInviteCodeCard(
    ShadThemeData theme,
    Map<String, dynamic>? activeStore,
  ) {
    final inviteCode = activeStore?['invite_code'] ?? '------';
    final storeId = activeStore?['id'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Warna.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  TablerIcons.ticket,
                  color: Color(0xFF0F172A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kode Undangan Toko',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Karyawan dapat memasukkan kode ini saat bergabung.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    inviteCode,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Salin Kode',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(TablerIcons.copy, size: 18, color: Color(0xFF475569)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteCode));
                    mySnackBar(
                      context: context,
                      text: 'Kode undangan disalin ke clipboard!',
                      status: ToastStatus.success,
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Buat Kode Baru',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(TablerIcons.refresh, size: 18, color: Color(0xFF475569)),
                  onPressed: () => _refreshInviteCode(storeId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        mySnackBar(
          context: context,
          text: 'Kode undangan berhasil direset!',
          status: ToastStatus.success,
        );
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Gagal memperbarui kode: $e',
          status: ToastStatus.error,
        );
      }
    }
  }

  Widget _buildSearchBar(ShadThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Cari nama atau email...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          prefixIcon: const Icon(
            TablerIcons.search,
            size: 18,
            color: Color(0xFF94A3B8),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(TablerIcons.x, size: 16, color: Color(0xFF94A3B8)),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildRoleFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'Semua'},
      {'key': 'owner', 'label': 'Owner'},
      {'key': 'karyawan', 'label': 'Kasir / Karyawan'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedRoleFilter == f['key'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedRoleFilter = f['key']!;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                f['label']!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddStaffButton(ShadThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Warna.primary,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () => _showAddStaffModal(theme),
        icon: const Icon(TablerIcons.user_plus, size: 18),
        label: const Text(
          'Tambah Staf Baru',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
        ),
      ),
    );
  }

  Widget _buildStaffList(
    ShadThemeData theme,
    bool isOwner,
    String? currentUserId,
    Map<String, dynamic>? activeStore,
  ) {
    final staffListAsync = ref.watch(staffListProvider);

    return staffListAsync.when(
      data: (staffList) {
        // Filter by role
        var filtered = staffList.where((staff) {
          final role = (staff['role'] ?? '').toString().toLowerCase();
          if (_selectedRoleFilter == 'owner') return role == 'owner';
          if (_selectedRoleFilter == 'karyawan') return role != 'owner';
          return true;
        }).toList();

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          filtered = filtered.where((staff) {
            final name = (staff['name'] ?? '').toString().toLowerCase();
            final email = (staff['email'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || email.contains(_searchQuery);
          }).toList();
        }

        if (filtered.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    TablerIcons.user_off,
                    size: 32,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Tidak ada staf yang sesuai "$_searchQuery"'
                      : 'Belum ada anggota staf di kategori ini.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final staff = filtered[index];
            final isSelf = staff['user_id'] == currentUserId;
            return _buildStaffCard(theme, staff, isOwner, isSelf, activeStore);
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(color: Warna.primary),
        ),
      ),
      error: (err, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(TablerIcons.alert_circle, color: Color(0xFFDC2626)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Gagal memuat staf: $err',
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard(
    ShadThemeData theme,
    Map<String, dynamic> staff,
    bool isOwner,
    bool isSelf,
    Map<String, dynamic>? activeStore,
  ) {
    final role = staff['role']?.toString() ?? 'Karyawan';
    final isStaffOwner = role.toLowerCase() == 'owner';
    final name = staff['name']?.toString() ?? 'Tanpa Nama';
    final email = staff['email']?.toString() ?? '-';
    final status = staff['status']?.toString() ?? 'active';
    final isActive = status.toLowerCase() == 'active';

    // Inisial untuk avatar
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelf
              ? Warna.primary.withValues(alpha: 0.6)
              : const Color(0xFFE2E8F0),
          width: isSelf ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar modern dengan inisial
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isStaffOwner
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isStaffOwner
                        ? const Color(0xFFBFDBFE)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isStaffOwner
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: Warna.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Anda',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildRoleBadge(role),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'Status Aktif' : 'Menunggu Konfirmasi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? const Color(0xFF047857)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
                // Tindakan hanya jika login sebagai Owner
                if (isOwner)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showEditStaffModal(
                          staff,
                          isSelf: isSelf,
                          isStoreOwner: staff['user_id'] == activeStore?['owner_id'],
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                TablerIcons.edit,
                                size: 13,
                                color: Color(0xFF0F172A),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isSelf) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _showDeleteStaffDialog(staff),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFEE2E2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  TablerIcons.trash,
                                  size: 13,
                                  color: Color(0xFFDC2626),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Hapus',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  const Text(
                    'Read-only',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final isOwner = role.toLowerCase() == 'owner';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOwner ? const Color(0xFFEEF2FF) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOwner ? const Color(0xFFC7D2FE) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOwner ? TablerIcons.shield : TablerIcons.device_laptop,
            size: 12,
            color: isOwner ? const Color(0xFF4338CA) : const Color(0xFF15803D),
          ),
          const SizedBox(width: 4),
          Text(
            isOwner ? 'Owner' : 'Kasir',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: isOwner ? const Color(0xFF4338CA) : const Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStaffModal(ShadThemeData theme) {
    final emailController = TextEditingController();
    String selectedRole = 'Karyawan';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isOwnerSelected = selectedRole == 'Owner';

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header dengan icon dan deskripsi
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Warna.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              TablerIcons.user_plus,
                              size: 20,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tambah Staf Baru',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    letterSpacing: -0.3,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Undang anggota tim yang sudah terdaftar di POS System',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Field Email Pengguna
                      const Text(
                        'Email Pengguna',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: emailController,
                          autofocus: true,
                          keyboardType: TextInputType.emailAddress,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Contoh: karyawan@example.com',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Icon(
                              TablerIcons.mail,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                          ),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Field Role / Peran
                      const Text(
                        'Peran / Hak Akses',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Role selector card toggle
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setSheetState(() => selectedRole = 'Karyawan');
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: !isOwnerSelected
                                      ? Warna.primary.withValues(alpha: 0.12)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: !isOwnerSelected
                                        ? Warna.primary
                                        : const Color(0xFFE2E8F0),
                                    width: !isOwnerSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      TablerIcons.device_laptop,
                                      size: 18,
                                      color: !isOwnerSelected
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Kasir / Staf',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12.5,
                                              color: !isOwnerSelected
                                                  ? const Color(0xFF0F172A)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          const Text(
                                            'Akses kasir & penjualan',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isOwnerSelected)
                                      const Icon(
                                        TablerIcons.circle_check_filled,
                                        size: 16,
                                        color: Warna.primary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setSheetState(() => selectedRole = 'Owner');
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isOwnerSelected
                                      ? const Color(0xFFEEF2FF)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isOwnerSelected
                                        ? const Color(0xFF6366F1)
                                        : const Color(0xFFE2E8F0),
                                    width: isOwnerSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      TablerIcons.shield,
                                      size: 18,
                                      color: isOwnerSelected
                                          ? const Color(0xFF4338CA)
                                          : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Owner',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12.5,
                                              color: isOwnerSelected
                                                  ? const Color(0xFF0F172A)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          const Text(
                                            'Akses kelola toko penuh',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isOwnerSelected)
                                      const Icon(
                                        TablerIcons.circle_check_filled,
                                        size: 16,
                                        color: Color(0xFF6366F1),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () =>
                                  Navigator.pop(bottomSheetContext),
                              child: const Text(
                                'Batal',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Warna.primary,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () async {
                                final email = emailController.text.trim();
                                if (email.isEmpty) {
                                  mySnackBar(
                                    context: context,
                                    text: 'Masukkan alamat email staf terlebih dahulu.',
                                    status: ToastStatus.warning,
                                  );
                                  return;
                                }

                                Navigator.pop(bottomSheetContext);
                                await _addStaff(email, selectedRole);
                              },
                              child: const Text(
                                'Tambahkan Staf',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
          mySnackBar(
            context: context,
            text: 'Pengguna dengan email $email belum terdaftar di sistem.',
            status: ToastStatus.error,
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
          mySnackBar(
            context: context,
            text: 'Pengguna sudah menjadi staf di toko ini.',
            status: ToastStatus.error,
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
        mySnackBar(
          context: context,
          text: 'Staf baru berhasil ditambahkan!',
          status: ToastStatus.success,
        );
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Gagal menambahkan staf: $e',
          status: ToastStatus.error,
        );
      }
    }
  }

  void _showEditStaffModal(
    Map<String, dynamic> staff, {
    required bool isSelf,
    required bool isStoreOwner,
  }) {
    String selectedRole = staff['role']?.toString() ?? 'Karyawan';
    String selectedStatus = staff['status']?.toString() ?? 'active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isOwnerSelected = selectedRole.toLowerCase() == 'owner';
          final isActiveSelected = selectedStatus.toLowerCase() == 'active';

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              TablerIcons.user_cog,
                              size: 20,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Edit Data Staf',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    letterSpacing: -0.3,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sesuaikan peran atau status untuk ${staff['name']}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      if (isStoreOwner) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                TablerIcons.shield_lock,
                                size: 18,
                                color: Color(0xFFD97706),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Akun ini adalah Pemilik Utama toko. Peran dan status akun dilindungi agar toko selalu memiliki penanggung jawab.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF92400E),
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Peran / Hak Akses
                      const Text(
                        'Peran / Hak Akses',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: isStoreOwner
                                  ? () {
                                      mySnackBar(
                                        context: context,
                                        text:
                                            'Pemilik Utama toko tidak dapat diubah menjadi Kasir demi keamanan toko.',
                                        status: ToastStatus.warning,
                                      );
                                    }
                                  : () {
                                      setSheetState(() => selectedRole = 'Karyawan');
                                    },
                              child: Opacity(
                                opacity: isStoreOwner ? 0.45 : 1.0,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !isOwnerSelected
                                        ? Warna.primary.withValues(alpha: 0.12)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: !isOwnerSelected
                                          ? Warna.primary
                                          : const Color(0xFFE2E8F0),
                                      width: !isOwnerSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        TablerIcons.device_laptop,
                                        size: 18,
                                        color: !isOwnerSelected
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Kasir / Staf',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12.5,
                                            color: !isOwnerSelected
                                                ? const Color(0xFF0F172A)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      if (!isOwnerSelected)
                                        const Icon(
                                          TablerIcons.circle_check_filled,
                                          size: 16,
                                          color: Warna.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setSheetState(() => selectedRole = 'Owner');
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isOwnerSelected
                                      ? const Color(0xFFEEF2FF)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isOwnerSelected
                                        ? const Color(0xFF6366F1)
                                        : const Color(0xFFE2E8F0),
                                    width: isOwnerSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      TablerIcons.shield,
                                      size: 18,
                                      color: isOwnerSelected
                                          ? const Color(0xFF4338CA)
                                          : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Owner',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                          color: isOwnerSelected
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    if (isOwnerSelected)
                                      const Icon(
                                        TablerIcons.circle_check_filled,
                                        size: 16,
                                        color: Color(0xFF6366F1),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status Akun
                      const Text(
                        'Status Akun',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setSheetState(() => selectedStatus = 'active');
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isActiveSelected
                                      ? const Color(0xFFF0FDF4)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isActiveSelected
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFE2E8F0),
                                    width: isActiveSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Aktif',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    if (isActiveSelected)
                                      const Icon(
                                        TablerIcons.circle_check_filled,
                                        size: 16,
                                        color: Color(0xFF10B981),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: isStoreOwner
                                  ? () {
                                      mySnackBar(
                                        context: context,
                                        text:
                                            'Status Pemilik Utama tidak dapat dinonaktifkan.',
                                        status: ToastStatus.warning,
                                      );
                                    }
                                  : () {
                                      setSheetState(() => selectedStatus = 'pending');
                                    },
                              child: Opacity(
                                opacity: isStoreOwner ? 0.45 : 1.0,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !isActiveSelected
                                        ? const Color(0xFFFEF3C7)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: !isActiveSelected
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFE2E8F0),
                                      width: !isActiveSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF59E0B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Pending',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12.5,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      if (!isActiveSelected)
                                        const Icon(
                                          TablerIcons.circle_check_filled,
                                          size: 16,
                                          color: Color(0xFFF59E0B),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () =>
                                  Navigator.pop(bottomSheetContext),
                              child: const Text(
                                'Batal',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Warna.primary,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () async {
                                Navigator.pop(bottomSheetContext);
                                await _updateStaff(
                                  memberId: staff['id'],
                                  userId: staff['user_id'],
                                  newRole: selectedRole,
                                  newStatus: selectedStatus,
                                );
                              },
                              child: const Text(
                                'Simpan Perubahan',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateStaff({
    required String memberId,
    required String userId,
    required String newRole,
    required String newStatus,
  }) async {
    final supabase = sb.Supabase.instance.client;
    final activeStore = await ref.read(activeStoreProvider.future);
    if (activeStore == null) return;

    // Keamanan 1: Jika user adalah pemilik utama toko di kolom stores.owner_id
    final isStoreOwner = userId == activeStore['owner_id'];
    if (isStoreOwner && (newRole.toLowerCase() != 'owner' || newStatus.toLowerCase() != 'active')) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Pemilik Utama toko harus selalu memiliki peran Owner dan status Aktif.',
          status: ToastStatus.error,
        );
      }
      return;
    }

    // Keamanan 2: Jika mengubah role menjadi bukan Owner, pastikan masih ada Owner lain yang aktif
    if (newRole.toLowerCase() != 'owner' || newStatus.toLowerCase() != 'active') {
      final currentStaff = ref.read(staffListProvider).value ?? [];
      final otherActiveOwners = currentStaff.where((s) =>
          s['id'] != memberId &&
          (s['role']?.toString().toLowerCase() == 'owner') &&
          (s['status']?.toString().toLowerCase() == 'active'));

      if (otherActiveOwners.isEmpty) {
        if (mounted) {
          mySnackBar(
            context: context,
            text: 'Toko harus memiliki minimal satu Owner aktif. Tambahkan atau tunjuk Owner lain terlebih dahulu.',
            status: ToastStatus.error,
          );
        }
        return;
      }
    }

    try {
      await supabase.from('store_members').update({
        'role': newRole,
        'status': newStatus,
      }).eq('id', memberId);

      ref.invalidate(staffListProvider);

      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Data staf berhasil diperbarui!',
          status: ToastStatus.success,
        );
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Gagal memperbarui staf: $e',
          status: ToastStatus.error,
        );
      }
    }
  }

  void _showDeleteStaffDialog(Map<String, dynamic> staff) {
    showShadDialog(
      context: context,
      builder: (dialogContext) => ShadDialog(
        title: const Text('Hapus Staf'),
        description: Text(
          'Apakah Anda yakin ingin menghapus ${staff['name']} dari toko? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ShadButton.destructive(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _deleteStaff(staff);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStaff(Map<String, dynamic> staff) async {
    final supabase = sb.Supabase.instance.client;
    final activeStore = await ref.read(activeStoreProvider.future);
    if (activeStore == null) return;

    final memberId = staff['id'];
    final userId = staff['user_id'];
    final role = (staff['role'] ?? '').toString().toLowerCase();

    // Proteksi 1: Pemilik Utama toko di stores.owner_id tidak dapat dihapus
    if (userId == activeStore['owner_id']) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Pemilik Utama toko tidak dapat dihapus.',
          status: ToastStatus.error,
        );
      }
      return;
    }

    // Proteksi 2: Jika staf yang dihapus berstatus Owner, pastikan masih ada Owner lain
    if (role == 'owner') {
      final currentStaff = ref.read(staffListProvider).value ?? [];
      final remainingOwners = currentStaff.where((s) =>
          s['id'] != memberId &&
          (s['role']?.toString().toLowerCase() == 'owner') &&
          (s['status']?.toString().toLowerCase() == 'active'));

      if (remainingOwners.isEmpty) {
        if (mounted) {
          mySnackBar(
            context: context,
            text: 'Tidak dapat menghapus Owner terakhir. Toko harus memiliki minimal satu Owner aktif.',
            status: ToastStatus.error,
          );
        }
        return;
      }
    }

    try {
      await supabase.from('store_members').delete().eq('id', memberId);

      ref.invalidate(staffListProvider);

      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Staf berhasil dihapus dari toko!',
          status: ToastStatus.success,
        );
      }
    } catch (e) {
      if (mounted) {
        mySnackBar(
          context: context,
          text: 'Gagal menghapus staf: $e',
          status: ToastStatus.error,
        );
      }
    }
  }

  Widget _buildLockOverlay(ShadThemeData theme) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.white.withValues(alpha: 0.35),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Warna.primary.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        color: Warna.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        TablerIcons.lock,
                        color: Warna.black,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Manajemen Staf & Hak Akses',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.h4.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Warna.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Warna.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            TablerIcons.sparkles,
                            color: Warna.black,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'FITUR PRO (STAFF MANAGEMENT)',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Warna.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tambah kasir, undang anggota tim via kode OTP, dan kelola peran hak akses staf memerlukan paket berlangganan UMKM Hebat atau Bisnis Skalabel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push('/subscription-plans');
                        },
                        icon: const Icon(TablerIcons.crown, size: 18),
                        label: const Text(
                          'Upgrade Paket Sekarang',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Warna.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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

