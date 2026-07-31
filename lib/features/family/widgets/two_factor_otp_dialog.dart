import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../services/two_factor_auth_service.dart';

const Color _kAmber = Color(0xFFFFB300);
const Color _kAmberDeep = Color(0xFF8A5A00);
const Color _kBlue = Color(0xFF1976D2);

/// Modern OTP entry — six auto-advancing digit boxes, paste support,
/// resend cooldown, inline error. Matches the look of Apple / Stripe /
/// Revolut step-up verification.
class TwoFactorOtpDialog extends StatefulWidget {
  const TwoFactorOtpDialog({
    super.key,
    required this.displayEmail,
    this.stepUpOnly = false,
  });

  final String displayEmail;
  final bool stepUpOnly;

  @override
  State<TwoFactorOtpDialog> createState() => _TwoFactorOtpDialogState();
}

class _TwoFactorOtpDialogState extends State<TwoFactorOtpDialog> {
  static const int _length = 6;

  final List<TextEditingController> _controllers =
      List.generate(_length, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_length, (_) => FocusNode());

  bool _verifying = false;
  bool _resending = false;
  int _resendSeconds = 0;
  String? _inlineError;
  Timer? _cooldown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _cooldown?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _tickCooldown() {
    _cooldown?.cancel();
    _cooldown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_resendSeconds > 0) _resendSeconds--;
      });
      if (_resendSeconds <= 0) _cooldown?.cancel();
    });
  }

  Future<void> _resend() async {
    if (_resending || _resendSeconds > 0) return;
    setState(() {
      _resending = true;
      _inlineError = null;
    });
    try {
      await TwoFactorAuthService.instance.sendEmailOtp(
        email: widget.displayEmail,
      );
      if (!mounted) return;
      _clearBoxes();
      setState(() => _resendSeconds = 45);
      _tickCooldown();
      _focusNodes.first.requestFocus();
      final inFallback = TwoFactorAuthService.instance.isInFallbackMode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            inFallback
                ? 'Email delivery is unavailable — try again in a minute.'
                : 'New code sent — check inbox and spam.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inlineError = e is AuthException
            ? e.message
            : 'Could not resend. Try again shortly.';
      });
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _clearBoxes() {
    for (final c in _controllers) {
      c.clear();
    }
  }

  Future<void> _verify() async {
    final raw = _code;
    if (raw.length < _length) {
      setState(() => _inlineError = 'Enter the 6-digit code from your email.');
      return;
    }

    setState(() {
      _verifying = true;
      _inlineError = null;
    });

    try {
      await TwoFactorAuthService.instance.verifyEmailOtp(
        token: raw,
        email: widget.displayEmail,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _inlineError = e is AuthException
            ? e.message
            : 'Invalid code. Use the latest code from your email.';
        _clearBoxes();
      });
      _focusNodes.first.requestFocus();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      _fillFromPaste(value);
      return;
    }
    if (value.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_code.length == _length && !_verifying) {
      _verify();
    }
  }

  void _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final isBackspace = event.logicalKey == LogicalKeyboardKey.backspace;
    if (isBackspace && _controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _fillFromPaste(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    for (int i = 0; i < _length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    final filled = digits.length.clamp(0, _length);
    final nextIndex = filled >= _length ? _length - 1 : filled;
    _focusNodes[nextIndex].requestFocus();
    if (_code.length == _length && !_verifying) _verify();
  }

  @override
  Widget build(BuildContext context) {
    final resendBusy = _resending || _resendSeconds > 0;
    final demoCode = TwoFactorAuthService.instance.visibleDemoFallbackCode;
    final demoReason = TwoFactorAuthService.instance.demoFallbackReason;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: _kBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.stepUpOnly
                        ? 'Verify it\'s you'
                        : 'Enable two-step verification',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13.2,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: widget.stepUpOnly
                        ? 'We sent a sign-in code to '
                        : 'Enter the 6-digit code we sent to ',
                  ),
                  TextSpan(
                    text: widget.displayEmail,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            if (demoCode != null) ...[
              const SizedBox(height: 12),
              _DemoCodeBanner(code: demoCode, reason: demoReason),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_length, (i) => _digitBox(i)),
            ),
            if (_inlineError != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _inlineError!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton.icon(
                  onPressed: resendBusy || _verifying ? null : _resend,
                  icon: _resending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: resendBusy ? Colors.grey : _kBlue,
                        ),
                  label: Text(
                    _resending
                        ? 'Sending…'
                        : (_resendSeconds > 0
                            ? 'Resend in ${_resendSeconds}s'
                            : 'Resend code'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: resendBusy ? Colors.grey : _kBlue,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed:
                      _verifying ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: _verifying ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _verifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _digitBox(int i) {
    final hasValue = _controllers[i].text.isNotEmpty;
    return SizedBox(
      width: 44,
      height: 54,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) => _onKey(i, event),
        child: TextField(
          controller: _controllers[i],
          focusNode: _focusNodes[i],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          enabled: !_verifying,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: hasValue
                ? _kBlue.withValues(alpha: 0.08)
                : const Color(0xFFF8FAFC),
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasValue
                    ? _kBlue.withValues(alpha: 0.45)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBlue, width: 1.8),
            ),
          ),
          onChanged: (v) => _onChanged(i, v),
        ),
      ),
    );
  }
}

class _DemoCodeBanner extends StatelessWidget {
  const _DemoCodeBanner({required this.code, this.reason});

  final String code;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: _kAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAmber.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: _kAmber, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debug code (dev build only)',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _kAmberDeep,
                    fontSize: 12.5,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason ?? 'Email delivery unavailable',
                  style: const TextStyle(
                    color: Color(0xFF6B5300),
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: _kAmberDeep,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy code',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code copied'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, color: _kAmberDeep, size: 18),
          ),
        ],
      ),
    );
  }
}
