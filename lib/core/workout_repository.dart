import 'package:supabase_flutter/supabase_flutter.dart';

/// Where workouts come from. Screens depend on this instead of Supabase so
/// tests can pass a fake.
abstract class WorkoutRepository {
  /// All workouts, or only those with `duration_minutes <= maxMinutes`.
  Future<List<Map<String, dynamic>>> fetchWorkouts({int? maxMinutes});
}

/// Reads the `workouts` table (needs `initSupabase()` to have run).
class SupabaseWorkoutRepository implements WorkoutRepository {
  const SupabaseWorkoutRepository();

  @override
  Future<List<Map<String, dynamic>>> fetchWorkouts({int? maxMinutes}) async {
    final query = Supabase.instance.client.from('workouts').select();
    return maxMinutes == null
        ? await query
        : await query.lte('duration_minutes', maxMinutes);
  }
}
