import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class FlexibleTable extends MultiChildRenderObjectWidget {
  
  
  const FlexibleTable({super.key, required List<FlexibleTableCell> super.children});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _FlexibleTableRenderObject();
  }
}

class _Skip {
  int col;
  int num;
  _FlexibleTableCellRenderObject c;
  bool last;
  double accumulatedHeights;

  _Skip(this.col, this.num, this.c, this.last, this.accumulatedHeights);
}


class _FlexibleTableRenderObject extends RenderBox
    with
        ContainerRenderObjectMixin<_FlexibleTableCellRenderObject, _CellData>,
        RenderBoxContainerDefaultsMixin<_FlexibleTableCellRenderObject, _CellData> {
  
  List<List<_FlexibleTableCellRenderObject>> rows = [];
  List<double> rowHeights = [];
  List<List<_Skip>> skip = [];
  double colSize = 0;
  int cols = 0;
  
  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth);
    rowHeights = [];
    skip = [];
    var children = getChildrenAsList();
    cols = children.where((c) => c.row == 0).map((c) => c.colSpan).sum;
    colSize = constraints.maxWidth / cols;
    rows = children.groupListsBy((c) => c.row).entries.toList().sortedBy<num>((e) => e.key).map((e) => e.value).toList();
    double currentY = 0;
    for (int i = 0; i < rows.length; i++) {
      skip.add([]);
    }
    for (var (currentRow, r) in rows.indexed) {
      double rowHeight = 0;
      double currentX = 0;
      for (var c in r) {
        c.layout(BoxConstraints(maxWidth: colSize * c.colSpan), parentUsesSize: true);
        rowHeight = max(rowHeight, c.size.height / c.rowSpan);
      }
      for (var sk in skip[currentRow]) {
        if (sk.last) {
          rowHeight = max(rowHeight, sk.c.size.height - sk.accumulatedHeights);
        } else {
          rowHeight = max(rowHeight, sk.c.size.height / sk.c.rowSpan);
        }
      }
      rowHeights.add(rowHeight);
      int currentCol = 0;
      for (var c in r) {
        var sk = skip[currentRow].firstWhereOrNull((s) => s.col == currentCol);
        if (sk != null) {
          currentX += colSize * sk.num;
          currentCol += sk.num;
          if (sk.last) {
            var c = sk.c;
            var pd = c.parentData as BoxParentData;
            double leftoverY = (sk.accumulatedHeights + rowHeight) - sk.c.size.height;
            pd.offset = pd.offset.translate(0, leftoverY / 2 + c.align.y * (leftoverY / 2));
          } else {
            sk.accumulatedHeights += rowHeight;
          }
        }
        if (c.rowSpan > 1) {
          for (int y = 1; y < c.rowSpan; y++) {
            skip[currentRow + y].add(_Skip(currentCol, c.colSpan, c, y == c.rowSpan - 1, rowHeight));
          }
        }
        double leftoverX = colSize * c.colSpan - c.size.width;
        double leftoverY = rowHeight - c.size.height;
        (c.parentData as BoxParentData).offset = Offset(currentX + leftoverX / 2 + c.align.x * (leftoverX / 2),
            c.rowSpan == 1 ? currentY + leftoverY / 2 + c.align.y * (leftoverY / 2) : currentY);
        currentX += colSize * c.colSpan;
        currentCol++;
      }
      currentY += rowHeight;
    }
    size = Size(constraints.maxWidth, currentY);
  }
  
  @override
  void setupParentData(covariant RenderObject child) {
    child.parentData = _CellData();
  }
  
  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
  
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
  
}

class _CellData extends ContainerBoxParentData<_FlexibleTableCellRenderObject> {}

class FlexibleTableCell extends SingleChildRenderObjectWidget {
  final int rowSpan;
  final int colSpan;
  final int row;
  final int col;
  final Alignment align;

  const FlexibleTableCell(
      {super.key, super.child, required this.row, required this.col, this.rowSpan = 1, this.colSpan = 1, this.align = Alignment.bottomLeft});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _FlexibleTableCellRenderObject(rowSpan, colSpan, row, col, align);
  }
}

class _FlexibleTableCellRenderObject extends RenderProxyBox {
  final int rowSpan;
  final int colSpan;
  final int row;
  final int col;
  final Alignment align;

  _FlexibleTableCellRenderObject(this.rowSpan, this.colSpan, this.row, this.col, this.align);
}
