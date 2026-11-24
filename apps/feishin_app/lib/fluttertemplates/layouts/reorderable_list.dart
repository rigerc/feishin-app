// Adapted from Flutter Templates Reorderable List (MIT). See ../LICENSE.
import 'package:flutter/material.dart';

class QueueReorderList extends StatelessWidget {
  const QueueReorderList({
    super.key,
    required this.count,
    required this.row,
    required this.reorder,
    required this.start,
    required this.padding,
    this.header,
  });

  final int count;
  final IndexedWidgetBuilder row;
  final ReorderCallback reorder;
  final ValueChanged<int> start;
  final EdgeInsets padding;
  final Widget? header;

  @override
  Widget build(BuildContext context) => ReorderableListView.builder(
    buildDefaultDragHandles: false,
    padding: padding,
    header: header,
    itemCount: count,
    itemBuilder: row,
    onReorderItem: reorder,
    onReorderStart: start,
  );
}
