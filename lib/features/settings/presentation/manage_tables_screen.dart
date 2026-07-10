import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos_mobile/core/theme/colors.dart';
import 'package:pos_mobile/core/widgets/app_snackbar.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_mobile/features/pos/providers/table_provider.dart';
import 'package:pos_mobile/features/auth/providers/store_provider.dart';
import 'package:pos_mobile/core/models/table.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ManageTablesScreen extends ConsumerStatefulWidget {
  const ManageTablesScreen({super.key});

  @override
  ConsumerState<ManageTablesScreen> createState() => _ManageTablesScreenState();
}

class _ManageTablesScreenState extends ConsumerState<ManageTablesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final tablesAsync = ref.watch(tableNotifierProvider);

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
          'Manajemen Meja',
          style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(tableNotifierProvider.future),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 24),
                _buildDefaultCapacityCard(theme),
                const SizedBox(height: 32),
                _buildAddButton(theme),
                const SizedBox(height: 24),
                tablesAsync.when(
                  data: (tables) => _buildTableList(theme, tables),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text('Gagal memuat meja: $err'),
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

  Widget _buildHeader(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atur Meja Restoran',
          style: theme.textTheme.h3.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Kelola tata letak dan kapasitas meja untuk memudahkan pelayanan pelanggan.',
          style: theme.textTheme.muted,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildAddButton(ShadThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ShadButton(
        backgroundColor: Warna.primary,
        hoverBackgroundColor: Warna.primary.withOpacity(0.8),
        onPressed: () => _showTableModal(theme),
        leading: const Icon(TablerIcons.plus, size: 18, color: Colors.black),
        child: const Text(
          'Tambah Meja Baru',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTableList(ShadThemeData theme, List<TableModel> tables) {
    if (tables.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(TablerIcons.table, size: 48, color: theme.colorScheme.muted),
              const SizedBox(height: 16),
              Text('Belum ada meja terdaftar.', style: theme.textTheme.muted),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tables.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final table = tables[index];
        return _buildTableItem(theme, table, index);
      },
    );
  }

  Widget _buildTableItem(ShadThemeData theme, TableModel table, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Warna.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              TablerIcons.table,
              color: Warna.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  table.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Kapasitas: ${table.capacity} Orang',
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          _buildStatusBadge(table.status),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(TablerIcons.edit, size: 18, color: Colors.black54),
            onPressed: () => _showTableModal(theme, table: table),
          ),
          IconButton(
            icon: const Icon(
              TablerIcons.trash,
              size: 18,
              color: Warna.destructive,
            ),
            onPressed: () => _showDeleteDialog(table),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'available':
        color = Warna.success;
        label = 'Tersedia';
        break;
      case 'occupied':
        color = Warna.destructive;
        label = 'Terisi';
        break;
      case 'cleaning':
        color = Colors.blue;
        label = 'Dibersihkan';
        break;
      case 'reserved':
        color = Colors.orange;
        label = 'Dipesan';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDefaultCapacityCard(ShadThemeData theme) {
    final activeStore = ref.watch(activeStoreProvider).value;
    final defaultCapacity = activeStore?['settings']?['operational']?['default_table_capacity'] ?? 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Warna.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Warna.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Warna.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(TablerIcons.users, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kapasitas Default',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Text(
                  'Kapasitas otomatis saat membuat meja baru.',
                  style: theme.textTheme.muted.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: ShadInput(
              initialValue: defaultCapacity.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (value) {
                final newCapacity = int.tryParse(value) ?? 2;
                _updateDefaultCapacity(newCapacity);
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0);
  }

  Future<void> _updateDefaultCapacity(int capacity) async {
    final activeStore = ref.read(activeStoreProvider).value;
    final currentSettings = Map<String, dynamic>.from(activeStore?['settings'] ?? {});
    final operational = Map<String, dynamic>.from(currentSettings['operational'] ?? {});
    
    operational['default_table_capacity'] = capacity;
    currentSettings['operational'] = operational;

    await ref.read(activeStoreProvider.notifier).updateSettings(currentSettings);
  }

  void _showTableModal(ShadThemeData theme, {TableModel? table}) {
    final activeStore = ref.read(activeStoreProvider).value;
    final defaultCapacity = activeStore?['settings']?['operational']?['default_table_capacity'] ?? 2;

    final nameController = TextEditingController(text: table?.name);
    final capacityController = TextEditingController(
      text: table?.capacity.toString() ?? defaultCapacity.toString(),
    );

    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text(table == null ? 'Tambah Meja Baru' : 'Edit Data Meja'),
        description: const Text('Masukkan nama meja dan kapasitasnya.'),
        child: Container(
          width: 400,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nama Meja',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ShadInput(
                controller: nameController,
                placeholder: const Text('Contoh: Meja 01, VIP 1'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Kapasitas (Orang)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ShadInput(
                controller: capacityController,
                placeholder: const Text('2'),
                keyboardType: TextInputType.number,
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
            onPressed: () async {
              final name = nameController.text.trim();
              final capacity =
                  int.tryParse(capacityController.text.trim()) ?? 2;

              if (name.isEmpty) return;

              try {
                if (table == null) {
                  await ref
                      .read(tableNotifierProvider.notifier)
                      .addTable(name, capacity);
                } else {
                  await ref
                      .read(tableNotifierProvider.notifier)
                      .updateTable(
                        table.copyWith(name: name, capacity: capacity),
                      );
                }
                if (mounted) Navigator.of(context).pop();

                mySnackBar(
                  context: context,
                  text: table == null ? 'Meja baru berhasil ditambahkan' : 'Data meja berhasil diperbarui',
                  status: ToastStatus.success,
                );
              } catch (e) {
                if (mounted) {
                  mySnackBar(
                    context: context,
                    text: 'Gagal menyimpan meja: $e',
                    status: ToastStatus.error,
                  );
                }
              }
            },
            child: const Text(
              'Simpan',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(TableModel table) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Hapus Meja'),
        description: Text(
          'Apakah Anda yakin ingin menghapus ${table.name}? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ShadButton.destructive(
            onPressed: () async {
              try {
                await ref
                    .read(tableNotifierProvider.notifier)
                    .deleteTable(table.id);
                if (mounted) Navigator.of(context).pop();
                mySnackBar(
                  context: context,
                  text: 'Meja berhasil dihapus',
                  status: ToastStatus.success,
                );
              } catch (e) {
                if (mounted) {
                  mySnackBar(
                    context: context,
                    text: 'Gagal menghapus meja: $e',
                    status: ToastStatus.error,
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
