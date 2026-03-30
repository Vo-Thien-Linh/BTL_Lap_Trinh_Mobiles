class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zsiumhckrkqemvkbwwqu.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpzaXVtaGNrcmtxZW12a2J3d3F1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NjgwMzYsImV4cCI6MjA5MDE0NDAzNn0.TPGjVRnZF5k9FlmUQkq3LEw-6DN_rc6I9w0Rrya0Ay8',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static void validate() {
    if (!isConfigured) {
      throw StateError(
        'Missing Supabase config. Set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
      );
    }
  }
}