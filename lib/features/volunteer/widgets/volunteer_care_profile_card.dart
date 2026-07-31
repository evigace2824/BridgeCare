import 'package:flutter/material.dart';

import '../../../models/job_application_model.dart';
import '../../../models/volunteer_care_profile.dart';

/// Read-only care profile block (used in apply flow and family review).
class VolunteerCareProfileCard extends StatelessWidget {
  const VolunteerCareProfileCard({
    super.key,
    this.profile,
    this.application,
    this.compact = false,
  }) : assert(profile != null || application != null);

  final VolunteerCareProfile? profile;
  final JobApplicationModel? application;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final name = profile?.displayName ?? application!.volunteerName;
    final verification =
        profile?.verificationStatus ?? application!.verificationStatus;
    final trust = profile?.trustLevel ?? application!.trustLevel;
    final rating = profile?.rating ?? application!.rating;
    final tasks = profile?.completedTasks ?? application!.completedTasks;
    final skills = profile?.skills ?? application!.skills;
    final transport =
        profile?.transportMethod ?? application!.transportMethod;
    final distance = profile?.distanceKm ?? application!.distanceKm;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'V',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      verification,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(Icons.star_rounded, rating.toStringAsFixed(1)),
              _chip(Icons.verified_user_rounded, trust),
              _chip(Icons.task_alt_rounded, '$tasks completed'),
              _chip(Icons.directions_walk_rounded, transport),
              _chip(Icons.straighten_rounded, '${distance.toStringAsFixed(1)} km'),
            ],
          ),
          if (!compact && skills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Skills: ${skills.take(5).join(' · ')}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
            ),
          ],
          if (profile?.availabilitySummary != null &&
              profile!.availabilitySummary.isNotEmpty &&
              !compact) ...[
            const SizedBox(height: 6),
            Text(
              'Usual availability: ${profile!.availabilitySummary}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
