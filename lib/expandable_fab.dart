import 'dart:math' as math;

import 'package:flutter/material.dart';

enum FabStyle { horizontal, vertical, arc, cross, shuffle }

class ExpandableFab extends StatefulWidget {
  ExpandableFab({
    Key? key,
    this.initialOpen,
    required this.distance,
    required this.children,
    required this.style,
    this.isExtendedFab = false,
    this.extendedFabTitle = "",
    this.closeOnPressChildItem = false,
  }) : super(key: key);

  final bool? initialOpen;
  final double distance;
  final List<ActionButton> children;
  final FabStyle style;
  bool isExtendedFab;
  String extendedFabTitle;
  bool closeOnPressChildItem;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;
  late FabStyle _style;

  @override
  void initState() {
    super.initState();
    _setStyle();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  void _setStyle() {
    if (widget.style == FabStyle.shuffle) {
      final styles = [FabStyle.arc, FabStyle.cross, FabStyle.horizontal];
      styles.shuffle();
      _style = styles[0];
    } else {
      _style = widget.style;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _setStyle();
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56.0,
      height: 56.0,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.close,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];

    final actionButtonWidgets = <ActionButtonWidget>[];

    bool verticalTitle = _style == FabStyle.horizontal;

    for (ActionButton actionButton in widget.children) {
      Widget? titleWidget;
      if (_style != FabStyle.arc && actionButton.title != null) {
        String title = "${actionButton.title}";
        titleWidget = verticalTitle
            ? VerticalTitle(text: title)
            : HorizontalTitle(text: title);
      }
      actionButtonWidgets.add(ActionButtonWidget(
        icon: actionButton.icon,
        title: titleWidget,
        verticalTilte: verticalTitle,
        onPressed: () {
          if (widget.closeOnPressChildItem) {
            _toggle();
          }
          actionButton.onPressed?.call();
        },
      ));
    }

    final count = widget.children.length;
    if (_style == FabStyle.arc) {
      final step = 90.0 / (count - 1);
      for (var i = 0, angleInDegrees = 0.0;
          i < count;
          i++, angleInDegrees += step) {
        children.add(
          _ExpandingActionButton(
            directionInDegrees: angleInDegrees,
            maxDistance: widget.distance,
            progress: _expandAnimation,
            child: actionButtonWidgets[i],
          ),
        );
      }
      return children;
    }

    double directionInDegrees = 0;

    if (_style == FabStyle.vertical) {
      directionInDegrees = 90;
    } else if (_style == FabStyle.horizontal) {
      directionInDegrees = 0;
    } else if (_style == FabStyle.cross) {
      directionInDegrees = 60;
    }

    for (var i = 0; i < count; i++) {
      final dist = widget.distance * (i + 1);

      children.add(
        _ExpandingActionButton(
          directionInDegrees: directionInDegrees,
          maxDistance: dist,
          progress: _expandAnimation,
          child: actionButtonWidgets[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: widget.isExtendedFab
              ? FloatingActionButton.extended(
                  onPressed: _toggle,
                  label: Text(widget.extendedFabTitle),
                  icon: const Icon(Icons.create),
                )
              : FloatingActionButton(
                  onPressed: _toggle,
                  child: const Icon(Icons.create),
                ),
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}

@immutable
class ActionButtonWidget extends StatelessWidget {
  const ActionButtonWidget({
    Key? key,
    this.onPressed,
    required this.icon,
    this.title,
    this.verticalTilte = false,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final Widget icon;
  final Widget? title;
  final bool verticalTilte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _buildChild(theme);
  }

  Widget _buildIcon(ThemeData theme) {
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.secondary,
      elevation: 4.0,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        color: theme.colorScheme.onSecondary,
      ),
    );
  }

  Widget _buildChild(ThemeData theme) {
    if (title == null) {
      return _buildIcon(theme);
    } else if (verticalTilte) {
      return Column(
        children: _buildChildren(theme),
      );
    } else {
      return Row(
        children: _buildChildren(theme),
      );
    }
  }

  List<Widget> _buildChildren(ThemeData theme) {
    final output = <Widget>[];

    output.add(title!);

    output.add(_buildIcon(theme));
    return output;
  }
}

class ActionButton {
  const ActionButton({
    this.onPressed,
    required this.icon,
    this.title,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String? title;
}

class HorizontalTitle extends StatelessWidget {
  const HorizontalTitle({Key? key, required this.text}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: Colors.amber,
      child: Text(text),
    );
  }
}

class VerticalTitle extends StatelessWidget {
  const VerticalTitle({Key? key, required this.text}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      color: Colors.amber,
      child: Wrap(
        runSpacing: 30,
        direction: Axis.vertical,
        alignment: WrapAlignment.center,
        children: text.split("").map((string) => Text(string)).toList(),
      ),
    );
  }
}
