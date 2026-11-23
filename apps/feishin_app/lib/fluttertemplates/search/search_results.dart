// Adapted from Flutter Templates Search Results (MIT). See ../LICENSE.
import 'package:core/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

class CatalogSearch extends StatefulWidget {
  const CatalogSearch({
    super.key,
    required this.label,
    required this.onChanged,
  });

  final String label;
  final ValueChanged<String> onChanged;

  @override
  State<CatalogSearch> createState() => _CatalogSearchState();
}

class _CatalogSearchState extends State<CatalogSearch> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SearchBar(
    controller: _controller,
    elevation: const WidgetStatePropertyAll(0),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: AppRadius.xl),
    ),
    backgroundColor: WidgetStatePropertyAll(
      Theme.of(context).colorScheme.surfaceContainerHigh,
    ),
    hintText: widget.label,
    leading: const Icon(Icons.search),
    onChanged: widget.onChanged,
    trailing: [
      IconButton(
        tooltip: 'Clear search',
        onPressed: () {
          _controller.clear();
          widget.onChanged('');
        },
        icon: const Icon(Icons.close),
      ),
    ],
  );
}
