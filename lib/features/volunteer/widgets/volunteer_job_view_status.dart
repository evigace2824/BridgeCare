import 'package:flutter/material.dart' show Color;

import '../../../models/job_application_model.dart';
import '../../../models/job_post_model.dart';
import '../../../services/job_post_service.dart';

/// Volunteer-facing job status (application flow, not direct accept).
enum VolunteerJobViewStatus {
  active,
  applicationSent,
  acceptedByFamily,
  inProgress,
  completedAwaitingConfirm,
  confirmed,
  rejected,
  expired,
}

abstract final class VolunteerJobStatusHelper {
  static VolunteerJobViewStatus of(JobPostModel job, String volunteerId) {
    final app = JobPostService.instance.applicationForPost(job.id, volunteerId);
    final effective = job.effectiveStatus;

    if (effective == JobPostStatus.expired) {
      return VolunteerJobViewStatus.expired;
    }
    if (effective == JobPostStatus.confirmed &&
        job.acceptedByVolunteerId == volunteerId) {
      return VolunteerJobViewStatus.confirmed;
    }
    if (effective == JobPostStatus.completed &&
        job.acceptedByVolunteerId == volunteerId) {
      return VolunteerJobViewStatus.completedAwaitingConfirm;
    }
    if (job.acceptedByVolunteerId == volunteerId) {
      return switch (effective) {
        JobPostStatus.inProgress => VolunteerJobViewStatus.inProgress,
        JobPostStatus.accepted => VolunteerJobViewStatus.acceptedByFamily,
        _ => VolunteerJobViewStatus.active,
      };
    }
    if (app?.status == JobApplicationStatus.rejected) {
      return VolunteerJobViewStatus.rejected;
    }
    if (app?.status == JobApplicationStatus.pending) {
      return VolunteerJobViewStatus.applicationSent;
    }
    if (effective == JobPostStatus.active) {
      return VolunteerJobViewStatus.active;
    }
    return VolunteerJobViewStatus.expired;
  }

  static String label(VolunteerJobViewStatus s) => switch (s) {
        VolunteerJobViewStatus.active => 'Active',
        VolunteerJobViewStatus.applicationSent => 'Application Sent',
        VolunteerJobViewStatus.acceptedByFamily => 'Accepted by Family',
        VolunteerJobViewStatus.inProgress => 'In Progress',
        VolunteerJobViewStatus.completedAwaitingConfirm => 'Completed',
        VolunteerJobViewStatus.confirmed => 'Confirmed',
        VolunteerJobViewStatus.rejected => 'Not selected',
        VolunteerJobViewStatus.expired => 'Expired',
      };

  static Color color(VolunteerJobViewStatus s) => switch (s) {
        VolunteerJobViewStatus.active => const Color(0xFF10B981),
        VolunteerJobViewStatus.applicationSent => const Color(0xFF6366F1),
        VolunteerJobViewStatus.acceptedByFamily => const Color(0xFF1B74E4),
        VolunteerJobViewStatus.inProgress => const Color(0xFFF59E0B),
        VolunteerJobViewStatus.completedAwaitingConfirm => const Color(0xFF6B7280),
        VolunteerJobViewStatus.confirmed => const Color(0xFF059669),
        VolunteerJobViewStatus.rejected => const Color(0xFFEF4444),
        VolunteerJobViewStatus.expired => const Color(0xFF9CA3AF),
      };
}
