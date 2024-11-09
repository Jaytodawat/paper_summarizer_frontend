// main.dart
import 'package:flutter/material.dart';
import 'package:paper_summarizer_frontend/PromptProvider.dart';

import 'package:paper_summarizer_frontend/PromptScreen.dart';
import 'package:paper_summarizer_frontend/ThemeProvider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ResponseProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'File Upload/Download Demo',
          theme: ThemeData.light(), // Light theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.tealAccent,
            scaffoldBackgroundColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF2C2C2C),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFF2C2C2C),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.tealAccent),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.tealAccent),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.tealAccent),
              ),
              labelStyle: TextStyle(color: Colors.tealAccent),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.tealAccent,
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: const PromptScreen(),
        );
      },
    );
  }
}
