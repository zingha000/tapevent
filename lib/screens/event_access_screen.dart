import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../theme/app_colors.dart';
import '../services/event_service.dart';
import '../main.dart' show supabase;
import 'event_manage_screen.dart';

Future<Event?> showAccessCodeDialog(BuildContext context, Event event) async {
  final userId = supabase.auth.currentUser?.id;
  final isCreator = userId != null && userId == event.createdBy;

  if (isCreator) {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_code_${event.id}') ?? false;
    if (seen) {
      return _showEnterCodeDialog(context, event);
    }
    final updatedEvent = await _showCreatorFlow(context, event);
    if (updatedEvent == null) return null;
    await prefs.setBool('seen_code_${event.id}', true);
    return _showEnterCodeDialog(context, updatedEvent);
  }
  return _showEnterCodeDialog(context, event);
}

Future<Event?> _showCreatorFlow(BuildContext context, Event event) async {
  final result = await showGeneralDialog<Event>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Kode Akses',
    barrierColor: Colors.black.withValues(alpha: 0.3),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, secondaryAnim, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12 * anim.value,
          sigmaY: 12 * anim.value,
        ),
        child: FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: _CreatorCodeDialog(event: event),
          ),
        ),
      );
    },
  );
  if (!context.mounted) return null;
  return result;
}

Future<Event?> _showEnterCodeDialog(BuildContext context, Event event) {
  return showGeneralDialog<Event>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Kode Akses',
    barrierColor: Colors.black.withValues(alpha: 0.3),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, secondaryAnim, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12 * anim.value,
          sigmaY: 12 * anim.value,
        ),
        child: FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: _EnterCodeDialog(event: event),
          ),
        ),
      );
    },
  );
}

// ─── Popup 1: Creator melihat / generate kode akses ───

class _CreatorCodeDialog extends StatefulWidget {
  final Event event;
  const _CreatorCodeDialog({required this.event});

  @override
  State<_CreatorCodeDialog> createState() => _CreatorCodeDialogState();
}

class _CreatorCodeDialogState extends State<_CreatorCodeDialog> {
  late String _accessCode;
  bool _copied = false;
  bool _regenerating = false;

  @override
  void initState() {
    super.initState();
    _accessCode = widget.event.accessCode;
  }

  Future<void> _regenerate() async {
    setState(() => _regenerating = true);
    try {
      final newCode = await EventService.regenerateAccessCode(widget.event.id);
      if (!mounted) return;
      setState(() {
        _accessCode = newCode;
        _copied = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal generate kode baru')),
      );
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _accessCode));
    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(AppRadius.global),
            border: Border.all(color: context.border, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.inner),
                ),
                child: const Icon(Icons.vpn_key_rounded, color: AppColors.accentBlue, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Kode Akses Event',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Bagikan kode ini ke panitia lain agar mereka bisa mengakses event',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.inner),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accentBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kode akses ini hanya ditampilkan sekali. Salin dan simpan dengan baik.',
                        style: TextStyle(fontSize: 12, color: AppColors.accentBlue, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: context.bg,
                  borderRadius: BorderRadius.circular(AppRadius.inner),
                  border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _accessCode.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _copied ? null : _copyCode,
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 18,
                    color: _copied ? AppColors.success : AppColors.accentBlue,
                  ),
                  label: Text(
                    _copied ? 'Tersalin' : 'Salin Kode',
                    style: TextStyle(
                      color: _copied ? AppColors.success : AppColors.accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _copied ? AppColors.success : AppColors.accentBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _regenerating ? null : _regenerate,
                  icon: _regenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18, color: AppColors.accentBlue),
                  label: const Text(
                    'Buat Kode Baru',
                    style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accentBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      final updated = widget.event.copyWith(accessCode: _accessCode);
                      Navigator.of(context).pop(updated);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('OK, Masuk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Popup 2: Masukkan kode akses ───

class _EnterCodeDialog extends StatefulWidget {
  final Event event;
  const _EnterCodeDialog({required this.event});

  @override
  State<_EnterCodeDialog> createState() => _EnterCodeDialogState();
}

class _EnterCodeDialogState extends State<_EnterCodeDialog> {
  final _codeController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() async {
    final input = _codeController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorText = 'Kode akses wajib diisi');
      return;
    }

    String storedCode = widget.event.accessCode;
    try {
      final current = await supabase
          .from('events')
          .select('access_code')
          .eq('id', widget.event.id)
          .maybeSingle();
      storedCode = current?['access_code']?.toString() ?? storedCode;
    } catch (_) {
      // Jika gagal ambil data terbaru, fallback ke kode dari objek event.
    }

    if (input.toUpperCase() != storedCode.trim().toUpperCase()) {
      setState(() => _errorText = 'Kode akses salah');
      return;
    }

    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      await EventService.recordOrganizerAccess(widget.event.id, userId);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventManageScreen(event: widget.event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(AppRadius.global),
            border: Border.all(color: context.border, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.inner),
                ),
                child: const Icon(Icons.lock_outline_rounded, color: AppColors.accentBlue, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Masukkan Kode Akses',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Masukkan kode akses untuk mengelola event',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _codeController,
                autofocus: true,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [_UpperCaseTextFormatter()],
                style: const TextStyle(fontSize: 18, letterSpacing: 3, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Kode',
                  errorText: _errorText,
                  filled: true,
                  fillColor: context.bg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.inner),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.inner),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.inner),
                    borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.inner),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Batal', style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.buttonGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Masuk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
