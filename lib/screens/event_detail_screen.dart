import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  Future<void> _openRegistrationForm(BuildContext context) async {
    final url = event.registrationFormUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formulir pendaftaran belum tersedia')),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka tautan')),
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: event.bannerUrl != null
                  ? Image.network(event.bannerUrl!, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF62440), Color(0xFFB80E2C)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.image_outlined, size: 48, color: Colors.white70),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.category!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  if (event.tagline != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.tagline!,
                      style: TextStyle(fontSize: 14, color: AppColors.lightTextSecondary),
                    ),
                  ],
                  const SizedBox(height: 20),

                  _InfoRow(
                    icon: AppIcons.calendar,
                    label: 'Jadwal',
                    value: _formatDate(event.startDate),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.groups_outlined,
                    label: 'Penyelenggara',
                    value: event.organizerName,
                  ),
                  if (event.contactPerson != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Contact Person',
                      value: event.contactPerson!,
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description ?? 'Belum ada deskripsi.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.lightTextSecondary),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _openRegistrationForm(context),
                      icon: const Icon(Icons.edit_document, color: Colors.white, size: 20),
                      label: const Text(
                        'Formulir Pendaftaran',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Akan membuka Google Form di luar aplikasi',
                      style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}