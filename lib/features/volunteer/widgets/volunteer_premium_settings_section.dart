import 'package:flutter/material.dart';

import '../../../models/volunteer_premium_settings.dart';
import '../../../services/volunteer_premium_service.dart';
import '../data/volunteer_store.dart';
import 'volunteer_theme.dart';

/// Premium volunteer preferences: radius, categories, schedule, transport, alerts.
class VolunteerPremiumSettingsSection extends StatefulWidget {
  const VolunteerPremiumSettingsSection({super.key});

  @override
  State<VolunteerPremiumSettingsSection> createState() =>
      _VolunteerPremiumSettingsSectionState();
}

class _VolunteerPremiumSettingsSectionState
    extends State<VolunteerPremiumSettingsSection> {
  late double _radius;
  late List<String> _categories;
  late List<String> _schedule;
  late String _transport;
  late bool _urgentAlerts;
  late bool _nearbyAlerts;

  static const _scheduleOptions = [
    'Weekday mornings',
    'Weekday afternoons',
    'Weekday evenings',
    'Weekend mornings',
    'Weekend afternoons',
    'Weekend evenings',
  ];

  @override
  void initState() {
    super.initState();
    _readFromStore();
  }

  void _readFromStore() {
    final s = VolunteerStore.instance;
    _radius = s.maxRadiusKm;
    _categories = List.from(s.preferredJobCategories);
    _schedule = List.from(s.availabilitySchedule);
    _transport = s.transport;
    _urgentAlerts = s.notifyUrgent;
    _nearbyAlerts = s.notifyNearby;
  }

  Future<void> _persist() async {
    final cap = VolunteerStore.instance.currentPlan.maxRadiusCapKm;
    final settings = VolunteerPremiumSettings(
      maxRadiusKm: _radius.clamp(1.0, cap),
      preferredJobCategories: _categories,
      availabilitySchedule: _schedule,
      transport: _transport,
      urgentJobAlerts: _urgentAlerts,
      nearbyJobAlerts: _nearbyAlerts,
    );
    await VolunteerPremiumService.instance.saveSettings(settings);
  }

  @override
  Widget build(BuildContext context) {
    final s = VolunteerStore.instance;
    final isPremium = s.currentPlan.isPremium;
    final cap = s.currentPlan.maxRadiusCapKm;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPremium
              ? const Color(0xFF7C3AED).withValues(alpha: 0.35)
              : VolunteerTheme.border,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: isPremium
                    ? const Color(0xFF7C3AED)
                    : VolunteerTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Premium settings',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: VolunteerTheme.textPrimary,
                  ),
                ),
              ),
              if (isPremium)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isPremium
                ? 'Tune job matching, radius up to 25 km, and priority alerts.'
                : 'Upgrade to Verified Premium to unlock professional job controls.',
            style: const TextStyle(
              fontSize: 12,
              color: VolunteerTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _label('Max search radius'),
          Text(
            '${_radius.toStringAsFixed(0)} km',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          Slider(
            value: _radius.clamp(1.0, cap),
            min: 1,
            max: cap,
            divisions: (cap - 1).toInt().clamp(1, 24),
            activeColor: const Color(0xFF7C3AED),
            onChanged: isPremium
                ? (v) {
                    setState(() => _radius = v);
                    s.setMaxRadius(v);
                    _persist();
                  }
                : null,
          ),
          _label('Preferred job categories'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final cat in VolunteerPremiumSettings.defaultCategories)
                FilterChip(
                  label: Text(cat, style: const TextStyle(fontSize: 11)),
                  selected: _categories.contains(cat),
                  onSelected: isPremium
                      ? (on) {
                          setState(() {
                            if (on) {
                              _categories.add(cat);
                            } else {
                              _categories.remove(cat);
                            }
                          });
                          s.setPreferredJobCategories(_categories);
                          _persist();
                        }
                      : null,
                  selectedColor:
                      const Color(0xFF7C3AED).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFF7C3AED),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _label('Availability schedule'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final slot in _scheduleOptions)
                FilterChip(
                  label: Text(slot, style: const TextStyle(fontSize: 10.5)),
                  selected: _schedule.contains(slot),
                  onSelected: isPremium
                      ? (on) {
                          setState(() {
                            if (on) {
                              _schedule.add(slot);
                            } else {
                              _schedule.remove(slot);
                            }
                          });
                          s.setAvailabilitySchedule(_schedule);
                          _persist();
                        }
                      : null,
                  selectedColor:
                      const Color(0xFF24B6A8).withValues(alpha: 0.2),
                  checkmarkColor: VolunteerTheme.brandAccent,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _label('Transport method'),
          DropdownButtonFormField<String>(
            value: VolunteerPremiumSettings.transportOptions.contains(_transport)
                ? _transport
                : VolunteerPremiumSettings.transportOptions.first,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              for (final t in VolunteerPremiumSettings.transportOptions)
                DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: isPremium
                ? (v) {
                    if (v == null) return;
                    setState(() => _transport = v);
                    s.setTransportMethod(v);
                    _persist();
                  }
                : null,
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Urgent job alerts',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: const Text(
              'Priority push for urgent premium jobs nearby',
              style: TextStyle(fontSize: 11, color: VolunteerTheme.textSecondary),
            ),
            value: _urgentAlerts,
            onChanged: isPremium
                ? (v) {
                    setState(() => _urgentAlerts = v);
                    s.toggleNotifyUrgent(v);
                    _persist();
                  }
                : null,
            activeThumbColor: VolunteerTheme.danger,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nearby job alerts',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: const Text(
              'Notify when new premium jobs appear in your radius',
              style: TextStyle(fontSize: 11, color: VolunteerTheme.textSecondary),
            ),
            value: _nearbyAlerts,
            onChanged: isPremium
                ? (v) {
                    setState(() => _nearbyAlerts = v);
                    s.toggleNotifyNearby(v);
                    _persist();
                  }
                : null,
            activeThumbColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          t,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: VolunteerTheme.textSecondary,
          ),
        ),
      );
}
