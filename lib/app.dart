import 'package:flutter/material.dart';
import 'features/library/library_screen.dart';

class SuperBookApp extends StatelessWidget {
  const SuperBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperBook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const LibraryScreen(),
    );
  }
}
