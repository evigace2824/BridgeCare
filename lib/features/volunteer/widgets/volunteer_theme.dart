import 'package:flutter/material.dart';

import '../data/volunteer_models.dart';

class VolunteerTheme {
  static const Color brandPrimary = Color(0xFF133A63);
  static const Color brandAccent = Color(0xFF24B6A8);
  static const Color background = Color(0xFFF2F6FA);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE3EAF3);
  static const Color textPrimary = Color(0xFF0F2540);
  static const Color textSecondary = Color(0xFF5A6A7A);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFFB8C00);
  static const Color danger = Color(0xFFE53935);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF133A63), Color(0xFF1F5DA0)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF24B6A8), Color(0xFF1FA59A)],
  );

  static IconData iconForKind(VolunteerTaskKind k) {
    switch (k) {
      case VolunteerTaskKind.groceries:
        return Icons.shopping_basket_rounded;
      case VolunteerTaskKind.pharmacy:
        return Icons.local_pharmacy_rounded;
      case VolunteerTaskKind.medicalVisit:
        return Icons.local_hospital_rounded;
      case VolunteerTaskKind.transport:
        return Icons.directions_car_filled_rounded;
      case VolunteerTaskKind.paperwork:
        return Icons.description_rounded;
      case VolunteerTaskKind.companionship:
        return Icons.diversity_3_rounded;
      case VolunteerTaskKind.homeHelp:
        return Icons.home_repair_service_rounded;
      case VolunteerTaskKind.emergency:
        return Icons.emergency_rounded;
    }
  }

  static String labelForKind(VolunteerTaskKind k) {
    switch (k) {
      case VolunteerTaskKind.groceries:
        return 'Groceries';
      case VolunteerTaskKind.pharmacy:
        return 'Pharmacy';
      case VolunteerTaskKind.medicalVisit:
        return 'Medical visit';
      case VolunteerTaskKind.transport:
        return 'Transport';
      case VolunteerTaskKind.paperwork:
        return 'Paperwork';
      case VolunteerTaskKind.companionship:
        return 'Companionship';
      case VolunteerTaskKind.homeHelp:
        return 'Home help';
      case VolunteerTaskKind.emergency:
        return 'Emergency';
    }
  }

  static Color colorForUrgency(VolunteerUrgency u) {
    switch (u) {
      case VolunteerUrgency.sos:
        return danger;
      case VolunteerUrgency.high:
        return warning;
      case VolunteerUrgency.medium:
        return brandAccent;
      case VolunteerUrgency.low:
        return const Color(0xFF7C4DFF);
    }
  }

  static String labelForUrgency(VolunteerUrgency u) {
    switch (u) {
      case VolunteerUrgency.sos:
        return 'SOS';
      case VolunteerUrgency.high:
        return 'Urgent';
      case VolunteerUrgency.medium:
        return 'Soon';
      case VolunteerUrgency.low:
        return 'Flexible';
    }
  }

  static String shortAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
