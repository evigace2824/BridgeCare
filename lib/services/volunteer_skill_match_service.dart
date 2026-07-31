import '../features/volunteer/data/volunteer_store.dart';
import '../models/job_post_model.dart';

/// Skill-based “Best Match” scoring for premium job posts.
class VolunteerSkillMatchService {
  VolunteerSkillMatchService._();
  static final VolunteerSkillMatchService instance =
      VolunteerSkillMatchService._();

  static const _careToSkills = {
    'Elderly care': ['elderly', 'companionship', 'home care'],
    'Medical visit': ['medical', 'doctor', 'hospital', 'accompaniment'],
    'Pharmacy': ['pharmacy', 'medication', 'pickup'],
    'Groceries': ['grocery', 'shopping'],
    'Home assistance': ['home', 'help', 'companionship'],
    'General help': ['help', 'companionship'],
  };

  /// 0.0–1.0 match score between volunteer skills and job care type.
  double score(JobPostModel job) {
    final skills = VolunteerStore.instance.skills
        .map((s) => s.toLowerCase())
        .toList();
    final preferred =
        VolunteerStore.instance.preferredJobCategories.map((c) => c.toLowerCase());
    final keywords = <String>{
      ...?_careToSkills[job.careType]?.map((k) => k.toLowerCase()),
      job.careType.toLowerCase(),
      ...preferred,
    };
    if (skills.isEmpty) return 0.35;

    var hits = 0;
    for (final kw in keywords) {
      if (skills.any((s) => s.contains(kw) || kw.contains(s))) hits++;
    }
    final preferredHit = preferred.any(
      (p) => job.careType.toLowerCase().contains(p) || p.contains(job.careType.toLowerCase()),
    );
    if (preferredHit) hits += 2;
    return (hits / (keywords.length + 2)).clamp(0.0, 1.0);
  }

  bool isBestMatch(JobPostModel job) =>
      VolunteerStore.instance.currentPlan.isPremium && score(job) >= 0.55;

  String? matchLabel(JobPostModel job) {
    if (!VolunteerStore.instance.currentPlan.isPremium) return null;
    if (isBestMatch(job)) return 'Best Match';
    if (score(job) >= 0.35) return 'Good fit';
    return null;
  }
}
