import 'package:flutter/material.dart';
import 'job_model.dart';
import 'job_storage.dart';

class FamilyJobsPage extends StatefulWidget {
  FamilyJobsPage({super.key});

  @override
  State<FamilyJobsPage> createState() => _FamilyJobsPageState();
}

class _FamilyJobsPageState extends State<FamilyJobsPage> {
  static const _bg = Color(0xFFF5F7FB);
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final myJobs =
        jobs.where((j) => j.createdBy == currentUserId).toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: const Text("My Job Posts")),
      body: myJobs.isEmpty
          ? const Center(child: Text("No jobs yet"))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: List.generate(
                myJobs.length,
                (i) => _jobCard(i, myJobs[i]),
              ),
            ),
    );
  }

  Widget _jobCard(int index, Job job) {
    final applicants = job.applicants; // always non-null now
    final isExpanded = _expanded.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // HEADER
          Row(
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (job.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "URGENT",
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          Text("${job.category} • ${job.hours}",
              style: const TextStyle(color: Colors.grey, fontSize: 12)),

          const SizedBox(height: 10),

          Text(job.description),

          const SizedBox(height: 14),

          Row(
            children: [
              _chip(job.salary, Colors.blue),
              const SizedBox(width: 8),
              if (job.requiresCertification)
                const Icon(Icons.verified, color: Colors.green),
              const Spacer(),
              Text("${applicants.length} applicants",
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),

          const SizedBox(height: 12),

          // TOGGLE
          GestureDetector(
            onTap: () {
              setState(() {
                isExpanded
                    ? _expanded.remove(index)
                    : _expanded.add(index);
              });
            },
            child: Row(
              children: [
                const Icon(Icons.people, size: 18),
                const SizedBox(width: 6),
                Text(
                  isExpanded ? "Hide applicants" : "View applicants",
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down),
              ],
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: applicants
                  .map<Widget>((a) => _applicantTile(a))
                  .toList(),
            ),
            secondChild: const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _applicantTile(Applicant a) {
    Color color;
    IconData icon;

    switch (a.status) {
      case 'accepted':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        icon = Icons.hourglass_bottom;
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [

          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, size: 16, color: color),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(a.userId,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),

          if (a.status == 'pending') ...[
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => setState(() => a.status = 'accepted'),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => setState(() => a.status = 'rejected'),
            ),
          ] else
            Text(a.status,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}