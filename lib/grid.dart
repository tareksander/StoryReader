import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class SimpleTable extends StatelessWidget {
  final List<SimpleTableCell> children;
  
  const SimpleTable({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(child: CustomMultiChildLayout(delegate: _GridDelegate(children), children: children.map((e) => e.child).toList(),));
  }
}

class _GridDelegate extends MultiChildLayoutDelegate {
  final List<SimpleTableCell> children;
  
  _GridDelegate(this.children);

  @override
  void performLayout(Size size) {
    // TODO ask each child for the size
    // create a grid out of the maximum sized in each row and column
    // position the children centered in their cells
    Map<SimpleTableCell, Size> sizes = {};
    for (var c in children) {
      sizes[c] = layoutChild((c.x, c.y), const BoxConstraints());
    }
    int minY = children.map((c) => c.y).min;
    int maxY = children.map((c) => c.y).max;
    double maxWidth = children.groupListsBy((c) => c.y).map((k, v) => MapEntry(k, v.map((c) => sizes[c]!.width).max)).values.max;
    double currentY = 0;
    for (int y = minY; y <= maxY; y++) {
      double currentX = 0;
      var rowChildren = children.where((c) => c.y == y).sortedBy<num>((c) => c.x);
      double rowHeight = rowChildren.map((c) => sizes[c]!.height).max;
      if (rowChildren.isEmpty) {
        continue;
      }
      for (var c in rowChildren) {
        positionChild((c.x, c.y), Offset(currentX, currentY));
        currentX += maxWidth / rowChildren.length;
      }
      currentY += rowHeight;
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    if (oldDelegate is _GridDelegate) {
      if (oldDelegate.children == children) {
        return false;
      }
    }
    return true;
  }
}


final class SimpleTableCell {
  final int x;
  final int y;
  late final Widget child;
  
  SimpleTableCell({required this.x, required this.y, required Widget child}) {
    this.child = LayoutId(id: (x, y), child: child);
  }
}





