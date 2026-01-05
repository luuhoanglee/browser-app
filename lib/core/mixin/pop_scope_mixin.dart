import 'package:flutter/material.dart';
import 'package:satreps_client_app/core/routes/route_cubit.dart';

mixin PopScopeMixin<T extends StatefulWidget> on State<T> {
  Future<bool> onWillPop() async => true;

  Widget customPopScope({ required Widget child }) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final allow = await onWillPop();
          if (allow && mounted) {
            RouteCubit.of().pop();
          }
        }
      },
      child: child,
    );
  }
}
