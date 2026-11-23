// Adapted from Flutter Templates Sectioned Settings Page (MIT). See ../../LICENSE.
import 'package:core/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      ...rows,
    ],
  );
}
