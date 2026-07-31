import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../../../services/auth_service.dart';
import 'role_selection_screen.dart';
import 'signup_basic_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final SignupBasicData data;
  final String phoneNumber;

  const PhoneVerificationScreen({
    super.key,
    required this.data,
    required this.phoneNumber,
  });

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends State<PhoneVerificationScreen> {
  static const Color _primary = Color(0xFF1976D2);

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  int _seconds = 30;
  Timer? _timer;

  bool _success = false;
  bool _isError = false;
  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _seconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _onChanged(String value, int index) {
    if (!RegExp(r'^\d?$').hasMatch(value)) {
      _controllers[index].clear();
      return;
    }

    if (_isError) {
      setState(() => _isError = false);
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  String _getCode() {
    return _controllers.map((e) => e.text).join();
  }

  Future<void> _confirm() async {
    final code = _getCode();
    if (code.length != 6) {
      setState(() => _isError = true);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _isError = false;
    });

    try {
      await AuthService.instance.verifyPhoneOtp(
        phoneNumber: widget.phoneNumber,
        code: code,
      );
      if (!mounted) return;
      setState(() => _success = true);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoleSelectionScreen(data: widget.data),
          ),
        );
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _skip() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleSelectionScreen(data: widget.data),
      ),
    );
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    try {
      await AuthService.instance.requestPhoneOtp(phoneNumber: widget.phoneNumber);
      if (!mounted) return;
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code resent.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Widget _codeBox(int i) {
    return SizedBox(
      width: 48,
      height: 58,
      child: TextField(
        controller: _controllers[i],
        focusNode: _focusNodes[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        ],
        maxLength: 1,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _isError ? Colors.red : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: _isError ? Colors.red : _primary,
              width: 1.5,
            ),
          ),
        ),
        onChanged: (v) => _onChanged(v, i),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      body: SingleChildScrollView(
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!_success) _mainCard(),

              if (_success)
                Padding(
                  padding: const EdgeInsets.only(top: 200),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 50),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Verified Successfully',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mainCard() {
    return Container(
      width: 430,
      margin: const EdgeInsets.symmetric(vertical: 40),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read,
                size: 40, color: _primary),
          ),

          const SizedBox(height: 16),

          const Text(
            'Verification Code',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'We’ve sent a 6-digit verification code to\n${widget.phoneNumber}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                List.generate(6, (i) => _codeBox(i)),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Confirm Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 14),

          if (_seconds > 0)
            Text(
              'Resend available in $_seconds s',
              style: const TextStyle(color: Colors.grey),
            )
          else
            TextButton(
              onPressed: _isResending ? null : _resendCode,
              child: _isResending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Resend Code',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),

          TextButton(
            onPressed: _skip,
            child: const Text(
              'Skip for now',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}