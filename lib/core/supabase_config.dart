import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_keys.dart';

/// Call once in `main()` before using [SupabaseWorkoutRepository].
Future<void> initSupabase() =>
    Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
