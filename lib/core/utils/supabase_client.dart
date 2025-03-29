// lib/core/utils/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';

late final SupabaseClient supabase;

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://ekxqwrhultufzhtoxyzk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVreHF3cmh1bHR1ZnpodG94eXprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5MDIxNzAsImV4cCI6MjA1ODQ3ODE3MH0.4Mmo4gaR_vbRCkbEBadUL0NdX0teX01rGavQAymp8Kg',
  );
  supabase = Supabase.instance.client;
}
