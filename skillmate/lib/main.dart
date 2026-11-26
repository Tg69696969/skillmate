import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'router.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const SkillMateApp());
}

class SkillMateApp extends StatelessWidget {
  const SkillMateApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'SkillMate',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routerConfig: appRouter,
      );
}
