import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nexus/features/security/lock_screen_view.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.dark,
);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorSchemeSeed: Colors.blueGrey,
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorSchemeSeed: Colors.blueGrey,
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const NexusApp());
}

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: "Mike's Admin",
          debugShowCheckedModeBanner: false,

          themeMode: currentMode,

          theme: lightTheme,
          darkTheme: darkTheme,

          home: const LockScreenView(),
        );
      },
    );
  }
}
