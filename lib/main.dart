import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Supabase
  await initializeSupabase();

  runApp(MyApp());
}
