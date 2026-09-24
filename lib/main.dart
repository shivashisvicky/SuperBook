import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await rive.RiveNative.init();
  runApp(const SuperBookApp());
}
