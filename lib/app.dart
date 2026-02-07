import 'package:flutter/material.dart';
import 'features/reader/reader_screen.dart';

class InteractiveBookApp extends StatelessWidget {
  const InteractiveBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const ReaderScreen(),
    );
  }
}
