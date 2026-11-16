import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase project the app reads workouts from. The anon key is public by
/// design (it ships inside the app); what it can read is limited by the
/// `workouts` table's RLS policies.
const String supabaseUrl = 'https://ryjxewdvrcpumnbivvrb.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ5anhld2R2cmNwdW1uYml2dnJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyNDExODMsImV4cCI6MjA5MDgxNzE4M30.hPv0-dv3UlUGWEVZgpUgULPn3omGDHHA3ExsrBTpuRQ';

/// Call once in `main()` before using [SupabaseWorkoutRepository].
Future<void> initSupabase() =>
    Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
