import 'package:flutter/material.dart';

class CustomBottomSheet extends StatefulWidget {
  final bool isVisible;
  final Widget child;
  final double heightFactor;
  final Color? backgroundColor;
  final Color? barrierColor;
  final VoidCallback? onDismiss;
  final bool enableDrag;
  final double dragHandleWidth;
  final double dragHandleHeight;
  final bool showDragHandle;

  const CustomBottomSheet({
    super.key,
    required this.isVisible,
    required this.child,
    this.heightFactor = 0.75,
    this.backgroundColor,
    this.barrierColor,
    this.onDismiss,
    this.enableDrag = true,
    this.dragHandleWidth = 40,
    this.dragHandleHeight = 4,
    this.showDragHandle = true,
  });

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  void didUpdateWidget(CustomBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible != widget.isVisible) {
      _dragOffset = 0;
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _isDragging = true;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.enableDrag) return;

    setState(() {
      _dragOffset += details.delta.dy;
      if (_dragOffset < 0) _dragOffset = 0;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    _isDragging = false;

    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * widget.heightFactor;

    if (_dragOffset > sheetHeight * 0.3) {
      widget.onDismiss?.call();
    } else {
      // Snap back
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * widget.heightFactor;

    if (!widget.isVisible && _dragOffset == 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: widget.onDismiss,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: widget.barrierColor ?? Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          // Sheet content
          AnimatedContainer(
            duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: widget.isVisible ? (sheetHeight - _dragOffset) : 0,
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? Colors.grey[100],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: sheetHeight - _dragOffset,
              child: Column(
                children: [
                  // Drag handle
                  if (widget.showDragHandle)
                    GestureDetector(
                      onVerticalDragStart: widget.enableDrag ? _handleDragStart : null,
                      onVerticalDragUpdate: widget.enableDrag ? _handleDragUpdate : null,
                      onVerticalDragEnd: widget.enableDrag ? _handleDragEnd : null,
                      child: Container(
                        height: 30,
                        alignment: Alignment.center,
                        child: Container(
                          width: widget.dragHandleWidth,
                          height: widget.dragHandleHeight,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  // Content
                  if (widget.isVisible)
                    Expanded(
                      child: widget.child,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomBottomSheetWrapper extends StatefulWidget {
  final Widget child;
  final bool isSheetVisible;
  final Widget Function(BuildContext) sheetBuilder;
  final VoidCallback? onSheetDismiss;
  final double sheetHeightFactor;
  final Color? sheetBackgroundColor;
  final Color? barrierColor;
  final bool enableDrag;
  final bool showDragHandle;

  const CustomBottomSheetWrapper({
    super.key,
    required this.child,
    required this.isSheetVisible,
    required this.sheetBuilder,
    this.onSheetDismiss,
    this.sheetHeightFactor = 0.75,
    this.sheetBackgroundColor,
    this.barrierColor,
    this.enableDrag = true,
    this.showDragHandle = true,
  });

  @override
  State<CustomBottomSheetWrapper> createState() =>
      _CustomBottomSheetWrapperState();
}

class _CustomBottomSheetWrapperState
    extends State<CustomBottomSheetWrapper> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        CustomBottomSheet(
          isVisible: widget.isSheetVisible,
          heightFactor: widget.sheetHeightFactor,
          backgroundColor: widget.sheetBackgroundColor,
          barrierColor: widget.barrierColor,
          onDismiss: widget.onSheetDismiss,
          enableDrag: widget.enableDrag,
          showDragHandle: widget.showDragHandle,
          child: widget.sheetBuilder(context),
        ),
      ],
    );
  }
}

class CustomBottomSheetController extends ChangeNotifier {
  bool _isVisible = false;

  bool get isVisible => _isVisible;

  void show() {
    if (!_isVisible) {
      _isVisible = true;
      notifyListeners();
    }
  }

  void hide() {
    if (_isVisible) {
      _isVisible = false;
      notifyListeners();
    }
  }

  void toggle() {
    _isVisible = !_isVisible;
    notifyListeners();
  }
}

class ControlledBottomSheet extends StatelessWidget {
  final CustomBottomSheetController controller;
  final Widget child;
  final double heightFactor;
  final Color? backgroundColor;
  final Color? barrierColor;
  final bool enableDrag;
  final bool showDragHandle;

  const ControlledBottomSheet({
    super.key,
    required this.controller,
    required this.child,
    this.heightFactor = 0.75,
    this.backgroundColor,
    this.barrierColor,
    this.enableDrag = true,
    this.showDragHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomBottomSheet(
          isVisible: controller.isVisible,
          heightFactor: heightFactor,
          backgroundColor: backgroundColor,
          barrierColor: barrierColor,
          onDismiss: controller.hide,
          enableDrag: enableDrag,
          showDragHandle: showDragHandle,
          child: this.child,
        );
      },
    );
  }
}
