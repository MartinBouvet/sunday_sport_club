import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Créer une instance unique de Supabase
late final SupabaseClient supabase;

// Initialiser Supabase
Future<void> initializeSupabase() async {
  await dotenv.load();

  String supabaseUrl =
      dotenv.env['SUPABASE_URL'] ?? 'https://ekxqwrhultufzhtoxyzk.supabase.co';
  String supabaseKey =
      dotenv.env['SUPABASE_ANON_KEY'] ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVreHF3cmh1bHR1ZnpodG94eXprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5MDIxNzAsImV4cCI6MjA1ODQ3ODE3MH0.4Mmo4gaR_vbRCkbEBadUL0NdX0teX01rGavQAymp8Kg';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  supabase = Supabase.instance.client;
}
