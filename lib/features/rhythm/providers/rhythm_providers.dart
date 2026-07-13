import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/local/database/app_database.dart';
import '../models/rhythm_recommendation.dart';
import '../services/rhythm_engine.dart';

final rhythmRecommendationProvider = FutureProvider<RhythmRecommendation?>((ref) async {
  final db = ref.watch(databaseProvider);
  final end = DateTime.now();
  final start = end.subtract(const Duration(days: 28));
  final sessions = await db.focusSessionsDao.getByDateRange(start, end);

  final rec = RhythmEngine.generateRecommendation(sessions);
  if (rec == null) return null;

  // Check dismiss state
  final prefs = await SharedPreferences.getInstance();
  final dismissedId = prefs.getString('flowos_rhythm_dismissed_id');
  final dismissedUntil = prefs.getInt('flowos_rhythm_dismissed_until') ?? 0;

  if (rec.id == dismissedId && DateTime.now().millisecondsSinceEpoch < dismissedUntil) {
    return null;
  }

  return rec;
});

final rhythmRecommendationControllerProvider = Provider((ref) => RhythmRecommendationController(ref));

class RhythmRecommendationController {
  final Ref _ref;
  RhythmRecommendationController(this._ref);

  Future<void> dismissRecommendation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('flowos_rhythm_dismissed_id', id);
    final until = DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch;
    await prefs.setInt('flowos_rhythm_dismissed_until', until);
    
    // Invalidate provider to trigger UI refresh
    _ref.invalidate(rhythmRecommendationProvider);
  }
}
