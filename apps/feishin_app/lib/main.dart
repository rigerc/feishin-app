import 'dart:convert';

import 'package:core/core/theme/app_theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'di/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  final theme = await rootBundle.loadString('assets/theme/theme_config.json');
  runApp(
    FeishinApp(
      theme: AppThemeConfig.fromJson(jsonDecode(theme) as Map<String, dynamic>),
    ),
  );
}
