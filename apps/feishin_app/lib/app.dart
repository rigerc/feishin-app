import 'package:core/core/theme/app_theme.dart';
import 'package:core/core/theme/app_theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'constants/value_const.dart';
import 'di/injection_container.dart';
import 'feature/home/domain/remote.dart';
import 'feature/home/presentation/bloc/home_bloc.dart';
import 'feature/home/presentation/view/home_page.dart';

class FeishinApp extends StatelessWidget {
  const FeishinApp({super.key, required this.theme});

  final AppThemeConfig theme;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => HomeBloc(sl(), sl())..add(const HomeEvent.started()),
    child: BlocSelector<HomeBloc, HomeState, ThemePreference>(
      selector: (state) => switch (state) {
        HomeLoading() => ThemePreference.dark,
        HomeReady(:final preferences) => preferences.theme,
      },
      builder: (_, preference) => MaterialApp(
        title: ValueConst.app,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.fromConfig(theme),
        darkTheme: AppTheme.fromConfig(theme, dark: true),
        themeMode: ThemeMode.values[preference.index],
        home: const HomePage(),
      ),
    ),
  );
}
