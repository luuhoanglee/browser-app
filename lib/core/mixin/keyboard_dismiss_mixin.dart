import 'package:flutter/material.dart';

mixin KeyboardDismissMixin<T extends StatefulWidget> on State<T> {
  void dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }
}
