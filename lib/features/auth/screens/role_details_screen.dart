import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../widgets/brand_logo_header.dart';
import 'signup_basic_screen.dart';
import 'verify_email_screen.dart';

class RoleDetailsScreen extends StatefulWidget {
  final String role;
  final SignupBasicData data;

  const RoleDetailsScreen({
    super.key,
    required this.role,
    required this.data,
  });

  @override
  State<RoleDetailsScreen> createState() => _RoleDetailsScreenState();
}

class _RoleDetailsScreenState extends State<RoleDetailsScreen> {
  static const Color _primary = Color(0xFF1976D2);
  static const Color _primaryDark = Color(0xFF1565C0);
  final TextEditingController _otherConditionController =
      TextEditingController();
  final List<String> _selectedConditions = [];
  bool _takesMedication = false;
  bool _isSubmitting = false;

  final List<TextEditingController> _medicationControllers = [
    TextEditingController(),
  ];
  final List<TimeOfDay?> _medicationTimes = [null];

  final TextEditingController _emergencyNameController =
      TextEditingController();
  final TextEditingController _emergencyPhoneController =
      TextEditingController();
  final TextEditingController _familyVerificationCodeController =
      TextEditingController();

  String _selectedRelation = 'Daughter';

  final List<String> _conditionOptions = [
    'Diabetes',
    'Hypertension',
    'Heart Disease',
    'Asthma',
    'Arthritis',
    'Mobility Issues',
    'Vision Problems',
    'Hearing Loss',
    "Alzheimer's",
    "Parkinson's",
    'Cancer',
    'Other',
  ];

  final List<String> _relationOptions = [
    'Daughter',
    'Son',
    'Spouse',
    'Parent',
    'Sibling',
    'Friend',
    'Caregiver',
    'Other',
  ];

  final List<int> _selectedDays = [];
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;

  final List<String> _selectedSkills = [];
  String _transport = 'None';

  final List<String> _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  final List<String> _skillOptions = [
    'Driving',
    'Medical Knowledge',
    'Assistance'
  ];
  final List<String> _transportOptions = [
    'None',
    'Car',
    'Motorcycle',
    'Other',
  ];

  UserRole _selectedRoleForSignup() {
    switch (widget.role.toLowerCase()) {
      case 'volunteer':
        return UserRole.volunteer;
      case 'family':
        return UserRole.family;
      case 'patient':
      default:
        return UserRole.elderly;
    }
  }

  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _finishSignup() async {
    if (_isSubmitting) return;
    final role = _selectedRoleForSignup();

    if (role == UserRole.family) {
      final linkCode = _familyVerificationCodeController.text.trim();
      if (linkCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enter the family link code from your loved one\'s BridgeCare profile.',
            ),
          ),
        );
        return;
      }
      final valid = await AuthService.instance.isFamilyLinkCodeValid(linkCode);
      if (!valid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'That family link code was not found. Ask your family member '
              'for the code shown on their profile (My family link code).',
            ),
          ),
        );
        return;
      }
    }

    final conditions = <String>[
      for (final c in _selectedConditions)
        if (c != 'Other') c,
      if (_selectedConditions.contains('Other') &&
          _otherConditionController.text.trim().isNotEmpty)
        _otherConditionController.text.trim(),
    ];

    final medications = <String>[];
    final medicationTimes = <String?>[];
    for (var i = 0; i < _medicationControllers.length; i++) {
      final name = _medicationControllers[i].text.trim();
      if (name.isEmpty) continue;
      medications.add(name);
      medicationTimes.add(_formatTime(_medicationTimes[i]));
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthService.instance.signOut();
      final outcome = await AuthService.instance.signUp(
        email: widget.data.email,
        password: widget.data.password,
        fullName: widget.data.name,
        role: role,
        phoneNumber: widget.data.phone,
        conditions: role == UserRole.elderly ? conditions : const [],
        takesMedication: role == UserRole.elderly ? _takesMedication : false,
        medications: role == UserRole.elderly ? medications : const [],
        medicationReminderTimes: role == UserRole.elderly
            ? medicationTimes
            : const [],
        emergencyContactName: role == UserRole.elderly
            ? _emergencyNameController.text.trim()
            : '',
        emergencyContactPhone: role == UserRole.elderly
            ? _emergencyPhoneController.text.trim()
            : '',
        emergencyRelation: role == UserRole.elderly ? _selectedRelation : '',
        availableDays: role == UserRole.volunteer ? _selectedDays : const [],
        availableFrom: role == UserRole.volunteer ? _formatTime(_fromTime) : null,
        availableTo: role == UserRole.volunteer ? _formatTime(_toTime) : null,
        skills: role == UserRole.volunteer ? _selectedSkills : const [],
        transport: role == UserRole.volunteer ? _transport : 'None',
        familyVerificationCode: role == UserRole.family
            ? _familyVerificationCodeController.text.trim()
            : '',
      );

      if (!mounted) return;
      switch (outcome) {
        case SignUpOutcome.autoSignedIn:
          await AuthService.instance.signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully. Please sign in.'),
              backgroundColor: _primary,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
          break;
        case SignUpOutcome.alreadyRegisteredConfirmed:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'An account with this email already exists. Please sign in.',
              ),
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
          break;
        case SignUpOutcome.needsEmailConfirmation:
        case SignUpOutcome.alreadyRegisteredUnconfirmed:
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(
                email: widget.data.email,
                alreadyRegistered:
                    outcome == SignUpOutcome.alreadyRegisteredUnconfirmed,
              ),
            ),
          );
          break;
      }
    } on AuthException catch (e) {
      if (!mounted) return;
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

  @override
  void dispose() {
    _otherConditionController.dispose();
    for (final c in _medicationControllers) {
      c.dispose();
    }
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _familyVerificationCodeController.dispose();
    super.dispose();
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _chipSelector({
    required List<String> options,
    required List<String> selected,
    required void Function(String) onTap,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () => onTap(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _primary.withAlpha(25) : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _primary : Colors.grey.shade300,
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? _primary : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _timeBox(TimeOfDay? time, String label, Function(TimeOfDay) onPick) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) {
          setState(() => onPick(picked));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: _primary),
            const SizedBox(width: 8),
            Text(
              time?.format(context) ?? label,
              style: TextStyle(
                color: time != null ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patientForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Health Information'),
const Text(
  'This information helps us provide better care and personalized support.',
  style: TextStyle(
    color: Colors.black54,
    fontSize: 13,
    height: 1.4,
  ),
),

const SizedBox(height: 12),
_chipSelector(
  options: _conditionOptions,
  selected: _selectedConditions,
  onTap: (condition) {
    setState(() {
      if (_selectedConditions.contains(condition)) {
        _selectedConditions.remove(condition);
      } else {
        _selectedConditions.add(condition);
      }

      if (!_selectedConditions.contains('Other')) {
        _otherConditionController.clear();
      }
    });
  },
),

if (_selectedConditions.contains('Other')) ...[
  const SizedBox(height: 12),
  TextFormField(
    controller: _otherConditionController,
    decoration: _inputDecoration(
      'Please specify condition',
      Icons.edit_outlined,
    ),
  ),
],

        const SizedBox(height: 20),

        const Text(
          'Currently taking medication?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),

        Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: _takesMedication,
              onChanged: (v) {
                if (v != null) setState(() => _takesMedication = v);
              },
            ),
            const Text('Yes'),
            Radio<bool>(
              value: false,
              groupValue: _takesMedication,
              onChanged: (v) {
                if (v != null) setState(() => _takesMedication = v);
              },
            ),
            const Text('No'),
          ],
        ),

        if (_takesMedication)
          Column(
            children: List.generate(_medicationControllers.length, (i) {
              return Column(
                children: [
                  TextFormField(
                    controller: _medicationControllers[i],
                    onChanged: (value) {
                      if (i == _medicationControllers.length - 1 &&
                          value.isNotEmpty) {
                        setState(() {
                          _medicationControllers.add(TextEditingController());
                          _medicationTimes.add(null);
                        });
                      }
                    },
                    decoration: _inputDecoration(
                        'Medication ${i + 1}', Icons.medication),
                  ),
                  _timeBox(
                      _medicationTimes[i], 'Select reminder time', (t) {
                    _medicationTimes[i] = t;
                  }),
                ],
              );
            }),
          ),

        const SizedBox(height: 10),

        _sectionLabel('Emergency Contact'),

        TextFormField(
          controller: _emergencyNameController,
          decoration:
              _inputDecoration('Emergency Contact Name', Icons.person_outline),
        ),

        const SizedBox(height: 12),

        TextFormField(
          controller: _emergencyPhoneController,
          keyboardType: TextInputType.phone,
          decoration:
              _inputDecoration('Emergency Contact Phone', Icons.phone_outlined),
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _selectedRelation,
          items: _relationOptions
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedRelation = v);
          },
          decoration:
              _inputDecoration('Relation to Patient', Icons.family_restroom),
        ),
      ],
    );
  }

  Widget _volunteerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Availability'),
const Text(
  'Tell us when you’re available and how you can help others.',
  style: TextStyle(
    color: Colors.black54,
    fontSize: 13,
    height: 1.4,
  ),
),

const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_dayLabels.length, (i) {
            final isSelected = _selectedDays.contains(i);
            return GestureDetector(
              onTap: () {
                setState(() {
                  isSelected ? _selectedDays.remove(i) : _selectedDays.add(i);
                });
              },
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _primary : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _dayLabels[i],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(child: _timeBox(_fromTime, 'From', (t) => _fromTime = t)),
            const SizedBox(width: 10),
            Expanded(child: _timeBox(_toTime, 'To', (t) => _toTime = t)),
          ],
        ),

        const SizedBox(height: 20),

        _sectionLabel('Skills'),
const Text(
  'Select your skills so we can match you with the right people.',
  style: TextStyle(
    color: Colors.black54,
    fontSize: 13,
    height: 1.4,
  ),
),

const SizedBox(height: 12),
        _chipSelector(
          options: _skillOptions,
          selected: _selectedSkills,
          onTap: (s) {
            setState(() {
              _selectedSkills.contains(s)
                  ? _selectedSkills.remove(s)
                  : _selectedSkills.add(s);
            });
          },
        ),

        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _transport,
          items: _transportOptions
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _transport = v);
          },
          decoration: _inputDecoration('Transport', Icons.directions_car),
        ),
      ],
    );
  }
Widget _familyForm() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Family link code'),

      const Text(
        'Ask your family member for the code on their BridgeCare profile '
        '("My family link code"). We do not email this code — they share it with you.',
        style: TextStyle(
          color: Colors.black54,
          fontSize: 13,
          height: 1.4,
        ),
      ),

      const SizedBox(height: 12),

      TextFormField(
        controller: _familyVerificationCodeController,
        textCapitalization: TextCapitalization.characters,
        decoration: _inputDecoration(
          'Family link code (e.g. CB-2026-A4F8)',
          Icons.verified_outlined,
        ),
      ),
    ],
  );
}
  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/signup', (_) => false);
    }
  }

  String _subtitleForRole() {
    switch (widget.role) {
      case 'Volunteer':
        return 'Tell us when and how you can help.';
      case 'Family':
        return 'Connect to your family member.';
      case 'Patient':
      default:
        return 'A few details so we can support you better.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLogoHeader(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: _goBack,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Back',
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete Profile',
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _subtitleForRole(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (widget.role == 'Patient') _patientForm(),
                  if (widget.role == 'Volunteer') _volunteerForm(),
                  if (widget.role == 'Family') _familyForm(),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _finishSignup,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Finish'),
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