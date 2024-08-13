import 'package:flutter/material.dart';

class GridExtended extends StatelessWidget {
  final List<GridCell> children;
  
  const GridExtended({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(delegate: _GridDelegate(children), children: children.map((e) => e.child).toList(),);
  }
}

class _GridDelegate extends MultiChildLayoutDelegate {
  final List<GridCell> children;
  
  _GridDelegate(this.children);

  @override
  void performLayout(Size size) {
    // TODO ask each child for the size
    // create a grid out of the maximum sized in each row and column
    // position the children centered in their cells
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


final class GridCell {
  final int startX;
  final int startY;
  final int sizeX;
  final int sizeY;
  late final Widget child;
  
  GridCell({required this.startX, required this.startY, this.sizeX = 1, this.sizeY = 1, required Widget child}) {
    this.child = LayoutId(id: [startX, startY], child: child);
  }
}


