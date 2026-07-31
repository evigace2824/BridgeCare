import 'package:flutter/material.dart';
import 'job_model.dart';
import 'job_storage.dart';

class JobsListPage extends StatefulWidget {
  const JobsListPage({super.key});

  @override
  State<JobsListPage> createState() => _JobsListPageState();
}

class _JobsListPageState extends State<JobsListPage> {
  Set<String> selectedFilters = {};

  List<Job> get filteredJobs {
    return jobs.where((job) {
      if (selectedFilters.contains("Full-time") &&
          !job.hours.contains("Full-time")) return false;

      if (selectedFilters.contains("Part-time") &&
          !job.hours.contains("Part-time")) return false;

      if (selectedFilters.contains("Urgent") && !job.isUrgent) return false;

      if (selectedFilters.contains("Certified") &&
          !job.requiresCertification) return false;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text("Jobs"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: filteredJobs.isEmpty
          ? const Center(child: Text("No jobs available"))
          : Column(
              children: [

                // 🔹 FILTER CHIPS
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
_chip("Full-time", Icons.schedule),
_chip("Part-time", Icons.timelapse),
_chip("Urgent", Icons.warning_amber_rounded),
_chip("Certified", Icons.verified),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 🔹 HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        "${filteredJobs.length} Jobs Found",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        "Newest",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 🔹 GRID
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredJobs.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemBuilder: (context, index) {
                      final job = filteredJobs[index];
                      return _jobCard(job);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // 🔹 JOB CARD (MEDICAL STYLE)
  Widget _jobCard(Job job) {
    final alreadyApplied =
        job.applicants.any((a) => a.userId == currentUserId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 🔹 TITLE
          Text(
            job.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 4),

          // 🔹 CATEGORY + HOURS
          Text(
            "${job.category} • ${job.hours}",
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 8),

          // 🔹 DESCRIPTION
          Text(
            job.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),

          const Spacer(),

          // 🔹 TAGS
          Wrap(
            spacing: 6,
            children: [
              _tag(job.category, const Color(0xFFE3F2FD), Colors.blue),
              if (job.isUrgent)
                _tag("Urgent", const Color(0xFFFFEBEE), Colors.red),
              if (job.requiresCertification)
                _tag("Certified", const Color(0xFFE8F5E9), Colors.green),
            ],
          ),

          const SizedBox(height: 10),

          // 🔹 SALARY
          Text(
            job.salary,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 10),

          // 🔹 APPLY BUTTON
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
onPressed: alreadyApplied
    ? null
    : () => _openApplyForm(context, job),
              child: Text(alreadyApplied ? "Applied" : "Apply"),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 FILTER CHIP
  Widget _chip(String text, IconData icon) {
  final isSelected = selectedFilters.contains(text);

  return GestureDetector(
    onTap: () {
      setState(() {
        isSelected
            ? selectedFilters.remove(text)
            : selectedFilters.add(text);
      });
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFE8F5E9) // soft green medical
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF4CAF50)
              : Colors.grey.shade300,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.green : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    ),
  );
}

  // 🔹 TAG
  Widget _tag(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
void _openApplyForm(BuildContext context, Job job) {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final noteController = TextEditingController();
  final otherRoleController = TextEditingController();
  final experienceController = TextEditingController();

  String selectedRole = "Nurse";
  bool hasCertification = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Center(
                    child: Text(
                      "Apply for Job",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 NAME
                  TextField(
                    controller: nameController,
                    decoration: _input("Full Name"),
                  ),

                  const SizedBox(height: 12),

                  // 🔹 PHONE
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _input("Phone Number"),
                  ),

                  const SizedBox(height: 12),

                  // 🔹 ROLE
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: [
                      "Nurse",
                      "Doctor",
                      "Caregiver",
                      "Physiotherapist",
                      "Other"
                    ]
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setModalState(() {
                        selectedRole = val!;
                      });
                    },
                    decoration: _input("Profession"),
                  ),

                  // 🔹 OTHER FIELD (FIXED)
                  if (selectedRole == "Other") ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: otherRoleController,
                      decoration: _input("Specify profession"),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // 🔹 EXPERIENCE (CLEAN INPUT)
                  TextField(
                    controller: experienceController,
                    keyboardType: TextInputType.number,
                    decoration: _input("Years of Experience"),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Example: 2, 5, 10",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),

                  const SizedBox(height: 12),

                  // 🔹 CERTIFICATION
                  SwitchListTile(
                    value: hasCertification,
                    onChanged: (val) {
                      setModalState(() {
                        hasCertification = val;
                      });
                    },
                    title: const Text("Certified"),
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 12),

                  // 🔹 NOTES (FIXED UI)
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: _input("Notes").copyWith(
                      hintText: "Write a short description about yourself...",
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔹 SUBMIT
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isEmpty ||
                            phoneController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Fill required fields"),
                            ),
                          );
                          return;
                        }

                        job.applicants.add(
                          Applicant(userId: nameController.text),
                        );

                        Navigator.pop(context);

                        setState(() {});
                      },
                      child: const Text("Submit"),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
InputDecoration _input(String label) {
  return InputDecoration(
    labelText: label,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
}