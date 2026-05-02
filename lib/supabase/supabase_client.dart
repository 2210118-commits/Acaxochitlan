import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const supabaseUrl = 'https://cqntluvwvtuexsbiyeqk.supabase.co';
  static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxbnRsdXZ3dnR1ZXhzYml5ZXFrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3NjExMTAsImV4cCI6MjA5MDMzNzExMH0.mNGXo8bUE9Jm1L5AM9i-mmJRZr9WOdN2i-RD9bqdQPQ';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
