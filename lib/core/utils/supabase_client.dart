import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/supabase_options.dart';

late final SupabaseClient supabase;

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: SupabaseOptions.supabaseUrl,
    anonKey: SupabaseOptions.supabaseAnonKey,
  );
  supabase = Supabase.instance.client;
}
