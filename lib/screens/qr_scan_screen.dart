import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_colors.dart';
import '../services/event_service.dart';
import '../main.dart' show supabase;
import '../widgets/lottie_loading.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> with TickerProviderStateMixin {
  bool _processing = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;
    if (rawValue == null) return;

    setState(() => _processing = true);
    await _controller.stop();

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      _showResult(false, 'Kamu belum login');
      return;
    }

    // Parse QR data format: "eventId:token:timeSlot"
    final parts = rawValue.split(':');
    if (parts.length != 3) {
      _showResult(false, 'Format QR tidak valid');
      return;
    }

    final eventId = parts[0];
    final token = parts[1];
    final timeSlot = int.tryParse(parts[2]);
    if (timeSlot == null) {
      _showResult(false, 'Format QR tidak valid');
      return;
    }

    final result = await EventService.checkInAttendance(
      eventId,
      userId,
      token: token,
      timeSlot: timeSlot,
    );
    _showResult(result['success'] as bool, result['message'] as String);
  }

  void _showResult(bool success, String message) {
    if (!mounted) return;
    final controller = AnimationController(vsync: this);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Lottie.asset(
                success
                    ? 'assets/animations/success_check.json'
                    : 'assets/animations/failed_check.json',
                controller: controller,
                onLoaded: (composition) {
                  controller
                    ..duration = composition.duration
                    ..forward().then((_) {
                      if (mounted) Navigator.of(context).pop();
                    });
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimary),
            ),
          ],
        ),
      ),
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Absen'),
        backgroundColor: AppColors.accentBlue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: SizedBox(width: 120, height: 120, child: LottieLoading()),
              ),
            ),
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
