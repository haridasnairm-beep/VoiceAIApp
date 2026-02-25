import 'package:flutter/material.dart';
import 'theme.dart';
import 'nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoiceNotesApp());
}

class VoiceNotesApp extends StatelessWidget {
  const VoiceNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VoiceNotes AI',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
