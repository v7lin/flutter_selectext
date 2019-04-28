import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_selectext/src/selectable_text_selection_controls.dart';
import 'package:flutter_selectext/src/text_selection_controls/handle_mark.dart';

const double _kHandleSize = 22.0;
// Minimal padding from all edges of the selection toolbar to all edges of the
// viewport.
const double _kToolbarScreenPadding = 8.0;

/// Manages a copy/paste text selection toolbar.
class _TextSelectionToolbar extends StatelessWidget {
  const _TextSelectionToolbar({
    Key key,
    @required this.markColor,
    this.handleCopy,
    this.handleSelectAll,
    this.handleMark,
  }) : super(key: key);

  final VoidCallback handleCopy;
  final VoidCallback handleSelectAll;
  final VoidCallback handleMark;
  final Color markColor;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = <Widget>[];
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);

    if (handleMark != null) {
      items.add(Padding(
        padding: EdgeInsets.all(8),
        child: RawMaterialButton(
          onPressed: handleMark,
          shape: new CircleBorder(
              side: BorderSide(color: Colors.grey, width: 3.0)),
          elevation: 2.0,
          fillColor: markColor,
        ),
      ));
    }

    if (handleCopy != null)
      items.add(FlatButton(
          child: Text(localizations.copyButtonLabel), onPressed: handleCopy));

    if (handleSelectAll != null)
      items.add(FlatButton(
          child: Text(localizations.selectAllButtonLabel),
          onPressed: handleSelectAll));

    return Material(
        elevation: 1.0,
        child: Container(
            height: 44.0,
            child: Row(mainAxisSize: MainAxisSize.min, children: items)));
  }
}

/// Centers the toolbar around the given position, ensuring that it remains on
/// screen.
class _TextSelectionToolbarLayout extends SingleChildLayoutDelegate {
  _TextSelectionToolbarLayout(
      this.screenSize, this.globalEditableRegion, this.position);

  /// The size of the screen at the time that the toolbar was last laid out.
  final Size screenSize;

  /// Size and position of the editing region at the time the toolbar was last
  /// laid out, in global coordinates.
  final Rect globalEditableRegion;

  /// Anchor position of the toolbar, relative to the top left of the
  /// [globalEditableRegion].
  final Offset position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final Offset globalPosition = globalEditableRegion.topLeft + position;

    double x = globalPosition.dx - childSize.width / 2.0;
    double y = globalPosition.dy - childSize.height;

    if (x < _kToolbarScreenPadding)
      x = _kToolbarScreenPadding;
    else if (x + childSize.width > screenSize.width - _kToolbarScreenPadding)
      x = screenSize.width - childSize.width - _kToolbarScreenPadding;

    if (y < _kToolbarScreenPadding)
      y = _kToolbarScreenPadding;
    else if (y + childSize.height > screenSize.height - _kToolbarScreenPadding)
      y = screenSize.height - childSize.height - _kToolbarScreenPadding;

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_TextSelectionToolbarLayout oldDelegate) {
    return position != oldDelegate.position;
  }
}

/// Draws a single text selection handle which points up and to the left.
class _TextSelectionHandlePainter extends CustomPainter {
  _TextSelectionHandlePainter({this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final double radius = size.width / 2.0;
    canvas.drawCircle(Offset(radius, radius), radius, paint);
    canvas.drawRect(Rect.fromLTWH(0.0, 0.0, radius, radius), paint);
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) {
    return color != oldPainter.color;
  }
}

class MaterialMarkTextSelectionControls
    extends SelectableTextSelectionControls {
  MaterialMarkTextSelectionControls(
      {@required this.markColor, this.handleMark});

  final HandleMark handleMark;
  final Color markColor;

  @override
  Size handleSize = const Size(_kHandleSize, _kHandleSize);

  TextSelection _selection(TextSelectionDelegate delegate) =>
      delegate.textEditingValue.selection;

  /// Builder for material-style copy/paste text selection toolbar.
  @override
  Widget buildToolbar(BuildContext context, Rect globalEditableRegion,
      Offset position, TextSelectionDelegate delegate) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));
    return ConstrainedBox(
        constraints: BoxConstraints.tight(globalEditableRegion.size),
        child: CustomSingleChildLayout(
          delegate: _TextSelectionToolbarLayout(
            MediaQuery.of(context).size,
            globalEditableRegion,
            position,
          ),
          child: _TextSelectionToolbar(
            handleCopy:
                isTextSelection(delegate) ? () => handleCopy(delegate) : null,
            handleMark: isTextSelection(delegate)
                ? () => handleMark(_selection(delegate))
                : null,
            markColor: markColor,
          ),
        ));
  }

  /// Builder for material-style text selection handles.
  @override
  Widget buildHandle(
      BuildContext context, TextSelectionHandleType type, double textHeight) {
    final Widget handle = Padding(
      padding: const EdgeInsets.only(right: 26.0, bottom: 26.0),
      child: SizedBox(
        width: _kHandleSize,
        height: _kHandleSize,
        child: CustomPaint(
          painter: _TextSelectionHandlePainter(
              color: Theme.of(context).textSelectionHandleColor),
        ),
      ),
    );

    // [handle] is a circle, with a rectangle in the top left quadrant of that
    // circle (an onion pointing to 10:30). We rotate [handle] to point
    // straight up or up-right depending on the handle type.
    switch (type) {
      case TextSelectionHandleType.left: // points up-right
        return Transform(
            transform: Matrix4.rotationZ(math.pi / 2.0), child: handle);
      case TextSelectionHandleType.right: // points up-left
        return handle;
      case TextSelectionHandleType.collapsed: // points up
        return Transform(
            transform: Matrix4.rotationZ(math.pi / 4.0), child: handle);
    }
    assert(type != null);
    return null;
  }
}
