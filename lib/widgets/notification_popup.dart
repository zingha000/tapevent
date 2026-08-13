import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../theme/app_colors.dart';

/// Tampilkan popup notifikasi.
/// - Bisa scroll bila isi notifikasi banyak.
/// - Punya tombol kembali di bagian atas.
/// - Tutup otomatis saat mengetuk di luar box notifikasi.
Future<void> showNotificationPopup(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Notifikasi',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => const _NotificationOverlay(),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
  );
}

class _NotificationOverlay extends StatelessWidget {
  const _NotificationOverlay();

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final panelWidth = (screen.width * 0.86).clamp(280.0, 420.0);

    return Stack(
      children: [
        // Area di luar box: klik di sini menutup popup.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        // Box notifikasi di tengah layar, ukuran menyesuaikan layar.
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: panelWidth,
              constraints: BoxConstraints(maxHeight: screen.height * 0.7),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(AppRadius.global),
                border: Border.all(color: context.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(),
                  const Divider(height: 1, thickness: 1),
                  Flexible(child: _NotificationList()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        children: [
          Text(
            'Notifikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Kembali',
            style: IconButton.styleFrom(
              backgroundColor: context.textSecondary.withValues(alpha: 0.08),
            ),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = buildDummyNotifications();

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_rounded,
              size: 36,
              color: context.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada notifikasi',
              style: TextStyle(color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, indent: 56, endIndent: 16),
      itemBuilder: (context, index) =>
          _NotificationTile(notification: items[index]),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  (Color, IconData) get _visual {
    switch (notification.type) {
      case NotificationType.eventNearby:
        return (const Color(0xFF3B82F6), Icons.calendar_month_rounded);
      case NotificationType.recommendation:
        return (const Color(0xFF8B5CF6), Icons.auto_awesome_rounded);
      case NotificationType.admin:
        return (AppColors.success, Icons.fact_check_rounded);
    }
  }

  String get _timeLabel {
    final diff = DateTime.now().difference(notification.createdAt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    final d = notification.createdAt;
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _visual;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!notification.read) ...[
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
