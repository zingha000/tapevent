import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/event_service.dart';
import '../widgets/lottie_loading.dart';

class AdminApprovalHistoryScreen extends StatefulWidget {
  const AdminApprovalHistoryScreen({super.key});

  @override
  State<AdminApprovalHistoryScreen> createState() => _AdminApprovalHistoryScreenState();
}

class _AdminApprovalHistoryScreenState extends State<AdminApprovalHistoryScreen> {
  List<Map<String, dynamic>> _allHistory = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _selectedFilter = 'semua';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await EventService.fetchApprovalHistory();
      if (!mounted) return;
      setState(() {
        _allHistory = history;
        _filteredHistory = history;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _filterHistory() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredHistory = _allHistory.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final organizer = (item['organizer_name'] ?? '').toString().toLowerCase();
        final matchesSearch = title.contains(query) || organizer.contains(query);

        if (_selectedFilter == 'semua') return matchesSearch;
        if (_selectedFilter == 'disetujui') return matchesSearch && item['status'] == 'active';
        if (_selectedFilter == 'ditolak') return matchesSearch && item['status'] != 'active';
        return matchesSearch;
      }).toList();
    });
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    final date = DateTime.parse(iso);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF62440), Color(0xFFD81336), Color(0xFFB80E2C)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 15,
                      right: -10,
                      child: Container(
                        width: 70,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2DB).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 28,
                      right: 10,
                      child: Container(
                        width: 45,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5BF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: -15,
                      child: Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFAF3).withOpacity(0.10),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Riwayat Persetujuan',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Daftar event yang sudah disetujui atau ditolak',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (_) => _filterHistory(),
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF1D1D1D)),
                                  decoration: InputDecoration(
                                    hintText: 'Cari berdasarkan judul atau organisasi...',
                                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                _buildFilterChip('semua', 'Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('disetujui', 'Disetujui'),
                const SizedBox(width: 8),
                _buildFilterChip('ditolak', 'Ditolak'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: SizedBox(width: 100, height: 100, child: LottieLoading()),
                  )
                : _filteredHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history_rounded, size: 40, color: context.textSecondary),
                            const SizedBox(height: 10),
                            Text(
                              _allHistory.isEmpty ? 'Belum ada event yang diproses' : 'Tidak ada hasil yang cocok',
                              style: TextStyle(color: context.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        itemCount: _filteredHistory.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: context.border),
                        itemBuilder: (context, index) {
                          final item = _filteredHistory[index];
                          final profile = item['profiles'] as Map<String, dynamic>?;
                          final isApproved = item['status'] == 'active';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] ?? '-',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Diajukan: ${profile?['full_name'] ?? '-'}',
                                        style: TextStyle(fontSize: 12, color: context.textSecondary),
                                      ),
                                      Text(
                                        'Organisasi: ${item['organizer_name'] ?? '-'}',
                                        style: TextStyle(fontSize: 12, color: context.textSecondary),
                                      ),
                                      Text(
                                        'Tanggal: ${_formatDate(item['created_at'])}',
                                        style: TextStyle(fontSize: 12, color: context.textSecondary),
                                      ),
                                      if (!isApproved && item['rejection_reason'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Alasan: ${item['rejection_reason']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.withOpacity(0.8),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isApproved ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isApproved ? 'Disetujui' : 'Ditolak',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isApproved ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        _filterHistory();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : context.textSecondary,
          ),
        ),
      ),
    );
  }
}
