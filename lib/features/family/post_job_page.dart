import 'package:flutter/material.dart';
import 'job_model.dart';
import 'job_storage.dart';

class PostJobPage extends StatefulWidget {
  const PostJobPage({super.key});

  @override
  State<PostJobPage> createState() => _PostJobPageState();
}

class _PostJobPageState extends State<PostJobPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _otherSkillController = TextEditingController();
  final _otherProfessionController = TextEditingController();

  double _minSalary = 200;
  double _maxSalary = 800;

  String _selectedCategory = 'Registered Nurse';
  String _selectedWorkType = 'Full-time';
  String _selectedSchedule = 'Day';
  String _selectedDuration = '8h';

  bool _requiresCertification = false;
  bool _isUrgent = false;

  final List<String> _categories = [
    'Registered Nurse',
    'Doctor / Physician',
    'Surgeon',
    'Physiotherapist',
    'Psychologist',
    'Dentist',
    'Pharmacist',
    'Medical Assistant',
    'Home Care Nurse',
    'Elderly Care Specialist',
    'Paramedic',
    'Other'
  ];

  final List<String> _skills = [
    'ICU Experience',
    'Elderly Care',
    'Medication Management',
    'Emergency Response',
    'Rehabilitation',
    'Other'
  ];

  final List<String> _selectedSkills = [];

  final List<String> _workTypes = ['Full-time', 'Part-time'];
  final List<String> _schedules = ['Day', 'Night', 'Flexible'];
  final List<String> _durations = ['4h', '8h', '12h'];

  static const _primary = Color(0xFF1976D2);
  static const _bg = Color(0xFFF6F8FB);

  void _submitJob() {
    if (_titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        _selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all required fields')),
      );
      return;
    }

    final skills = _selectedSkills.contains('Other')
        ? [..._selectedSkills, _otherSkillController.text]
        : _selectedSkills;

    final profession = _selectedCategory == 'Other'
        ? _otherProfessionController.text
        : _selectedCategory;

    jobs.add(
      Job(
        title: _titleController.text,
        description: "${_descController.text}\nSkills: ${skills.join(', ')}",
        category: profession,
        hours:
            "$_selectedWorkType • $_selectedSchedule • $_selectedDuration",
        salary: "€${_minSalary.toInt()} - €${_maxSalary.toInt()}",
        requiresCertification: _requiresCertification,
        isUrgent: _isUrgent,
        createdBy: currentUserId,
      ),
    );

    Navigator.pop(context);
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _primary.withAlpha(40) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? _primary : Colors.black87,
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: _bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override

Widget build(BuildContext context) {
  final safeCategory = _categories.contains(_selectedCategory)
      ? _selectedCategory
      : _categories.first;

  return Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    appBar: AppBar(
      title: const Text("Post Job"),
      elevation: 0,
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Create Job Request",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // ROLE
                _label("Role"),
                TextField(
                  controller: _titleController,
                  decoration: _input("e.g. Home Care Nurse", Icons.work),
                ),

                const SizedBox(height: 16),

                // PROFESSION
                _label("Profession"),
                DropdownButtonFormField(
                  value: safeCategory,
                  decoration: _input("", Icons.local_hospital),
                  items: _categories
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedCategory = v as String),
                ),

                if (safeCategory == 'Other')
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextField(
                      controller: _otherProfessionController,
                      decoration: _input("Specify profession", Icons.edit),
                    ),
                  ),

                const SizedBox(height: 16),

                // DESCRIPTION
                _label("Description"),
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: _input("Patient condition...", Icons.notes),
                ),

                const SizedBox(height: 20),

                // SKILLS
                _sectionCard(
                  title: "Required Skills",
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skills.map((skill) {
                      final selected = _selectedSkills.contains(skill);
                      return _chip(skill, selected, () {
                        setState(() {
                          selected
                              ? _selectedSkills.remove(skill)
                              : _selectedSkills.add(skill);
                        });
                      });
                    }).toList(),
                  ),
                ),

                if (_selectedSkills.contains('Other'))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextField(
                      controller: _otherSkillController,
                      decoration: _input("Specify other skill", Icons.edit),
                    ),
                  ),

                const SizedBox(height: 16),

                // SHIFT SECTION
                _sectionCard(
                  title: "Work Setup",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text("Work Type"),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: _workTypes.map((t) {
                          return _chip(
                            t,
                            _selectedWorkType == t,
                            () => setState(() => _selectedWorkType = t),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),

                      const Text("Schedule"),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: _schedules.map((s) {
                          return _chip(
                            s,
                            _selectedSchedule == s,
                            () => setState(() => _selectedSchedule = s),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),

                      const Text("Shift Duration"),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: _durations.map((d) {
                          return _chip(
                            d,
                            _selectedDuration == d,
                            () => setState(() => _selectedDuration = d),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // SALARY
                _sectionCard(
                  title: "Salary Range",
                  child: Column(
                    children: [
                      RangeSlider(
                        values: RangeValues(_minSalary, _maxSalary),
                        min: 100,
                        max: 2000,
                        labels: RangeLabels(
                          "€${_minSalary.toInt()}",
                          "€${_maxSalary.toInt()}",
                        ),
                        onChanged: (v) => setState(() {
                          _minSalary = v.start;
                          _maxSalary = v.end;
                        }),
                      ),
                      Row(
                        children: [
                          Text("€${_minSalary.toInt()}"),
                          const Spacer(),
                          Text("€${_maxSalary.toInt()}"),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // TOGGLES
                _sectionCard(
                  title: "Preferences",
                  child: Column(
                    children: [
                      _modernToggle("Certification Required",
                          _requiresCertification,
                          (v) => setState(() => _requiresCertification = v)),
                      const SizedBox(height: 10),
                      _modernToggle("Urgent Hiring",
                          _isUrgent,
                          (v) => setState(() => _isUrgent = v)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitJob,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text("Post Job"),
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
Widget _label(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}

Widget _sectionCard({required String title, required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

Widget _modernToggle(
    String label, bool value, Function(bool) onChanged) {
  return GestureDetector(
    onTap: () => onChanged(!value),
    child: Row(
      children: [
        Icon(
          value ? Icons.check_circle : Icons.circle_outlined,
          color: value ? Colors.blue : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    ),
  );
}
}