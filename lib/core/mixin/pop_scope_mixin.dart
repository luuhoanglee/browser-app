import 'package:flutter/material.dart';

mixin PopScopeMixin<T extends StatefulWidget> on State<T> {
  Future<bool> onWillPop() async => true;

  Widget customPopScope({ required Widget child }) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final allow = await onWillPop();
          if (allow && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: child,
    );
  }
}
