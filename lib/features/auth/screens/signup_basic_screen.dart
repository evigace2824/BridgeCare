import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/password_policy.dart';
import '../../../services/auth_service.dart';
import '../widgets/password_requirements_hint.dart';
import '../widgets/social_auth_section.dart';
import 'role_selection_screen.dart';

class SignupBasicData {
  String name;
  String email;
  String phone;
  String password;

  SignupBasicData({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });
}

class SignupBasicScreen extends StatefulWidget {
  const SignupBasicScreen({super.key});

  @override
  State<SignupBasicScreen> createState() => _SignupBasicScreenState();
}

class _SignupBasicScreenState extends State<SignupBasicScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPassController = TextEditingController();

  String _countryCode = '+355';

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _passwordInvalid = false;
  bool _oauthLoading = false;

  OverlayEntry? _tooltipEntry;

  static const Color _primary = Color(0xFF1976D2);

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  void dispose() {
    _removeTooltip();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, IconData icon,
      {Widget? suffix, bool isError = false}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: _primary),
      labelText: label,
      labelStyle: GoogleFonts.inter(),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
            color: isError ? Colors.red : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
            color: isError ? Colors.red : _primary, width: 1.5),
      ),
      suffixIcon: suffix,
    );
  }

  Widget _field(
    String label,
    IconData icon, {
    TextEditingController? controller,
    bool isPassword = false,
    bool? showPassword,
    Widget? suffix,
    bool isError = false,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !(showPassword ?? false),
        style: GoogleFonts.inter(),
        onChanged: onChanged,
        validator: validator,
        decoration:
            _decoration(label, icon, suffix: suffix, isError: isError),
      ),
    );
  }

  Widget _phoneField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CountryCodePicker(
            onChanged: (c) {
              _countryCode = c.dialCode ?? '+355';
            },
            initialSelection: 'AL',
            favorite: const ['+355'],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              style: GoogleFonts.inter(),
              decoration:
                  _decoration('Phone Number', Icons.phone),
            ),
          ),
        ],
      ),
    );
  }

  void _showTooltip() {
    final overlay = Overlay.of(context);

    _tooltipEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.black.withValues(alpha: 0.1),
          child: GestureDetector(
            onTap: _removeTooltip,
            child: Center(
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GestureDetector(
                  onTap: () {},
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Password must contain:",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.close, size: 18),
                            onPressed: _removeTooltip,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      PasswordRequirementsHint(
                        password: _passwordController.text,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_tooltipEntry!);
  }

  void _removeTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    final signupData = SignupBasicData(
      name: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: '$_countryCode${_phoneController.text.trim()}',
      password: _passwordController.text.trim(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleSelectionScreen(data: signupData),
      ),
    );
  }

  void _skip() {
    final dummyData = SignupBasicData(
      name: 'Test User',
      email: 'test@test.com',
      phone: '+3550000000',
      password: 'Test123!',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleSelectionScreen(data: dummyData),
      ),
    );
  }

  Future<void> _oauthGoogle() async {
    setState(() => _oauthLoading = true);
    try {
      final profile = await AuthService.instance.signInWithGoogle();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        profile.postAuthRoute,
        (route) => false,
      );
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _oauthLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      body: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          child: Container(
            width: 430,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: _goBack,
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const Icon(Icons.favorite,
                      color: _primary, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'Create Account',
                    style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _primary),
                  ),
                  const SizedBox(height: 20),
                  _field('Full Name', Icons.person_outline,
                      controller: _fullNameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      }),
                  _field('Email Address', Icons.email_outlined,
                      controller: _emailController,
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Please enter your email';
                        if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      }),
                  _phoneField(),
                  Row(
                    children: [
                      Text('Password',
                          style: GoogleFonts.inter()),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          if (_tooltipEntry != null) {
                            _removeTooltip();
                          } else {
                            _showTooltip();
                          }
                        },
                        child:
                            const Icon(Icons.info_outline, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _field(
                    '',
                    Icons.lock_outline,
                    controller: _passwordController,
                    isPassword: true,
                    showPassword: _showPassword,
                    isError: _passwordInvalid,
                    onChanged: (value) {
                      setState(() {
                        _passwordInvalid =
                            PasswordPolicy.validate(value) != null;
                      });
                    },
                    validator: PasswordPolicy.validate,
                    suffix: IconButton(
                      icon: Icon(_showPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                  ),
                  _field(
                    'Confirm Password',
                    Icons.lock_outline,
                    controller: _confirmPassController,
                    isPassword: true,
                    showPassword: _showConfirmPassword,
                    suffix: IconButton(
                      icon: Icon(_showConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _showConfirmPassword =
                              !_showConfirmPassword;
                        });
                      },
                    ),
                    validator: (v) =>
                        v != _passwordController.text
                            ? 'Passwords do not match'
                            : null,
                  ),
                  const SizedBox(height: 20),
                  SocialAuthSection(
                    isBusy: _oauthLoading,
                    onGoogle: _oauthGoogle,
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _oauthLoading ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                      ),
                      child: Text(
                        'Continue',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: _skip,
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}