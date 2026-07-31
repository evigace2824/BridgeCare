import '../models/family_models.dart';

class HealthService {
  Future<List<VitalReading>> getHeartRates(String elderlyUid) async {
    final now = DateTime.now();
    return List.generate(
      7,
      (i) => VitalReading(
        value: 67 + (i % 3) * 4,
        timestamp: now.subtract(Duration(days: 6 - i)),
        unit: 'bpm',
      ),
    );
  }

  Future<List<VitalReading>> getBloodPressures(String elderlyUid) async {
    final now = DateTime.now();
    return List.generate(
      7,
      (i) => VitalReading(
        value: 116 + (i % 3) * 5,
        secondaryValue: 75 + (i % 2) * 4,
        timestamp: now.subtract(Duration(days: 6 - i)),
        unit: 'mmHg',
      ),
    );
  }
}
