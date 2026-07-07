import 'package:flutter/material.dart';

class LogoApp extends StatelessWidget {
  const LogoApp({super.key, required this.isIncognito});
  final bool isIncognito;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/logo/logo-no-background.png',
          width: 36,
        ),
        Image.asset(
          'assets/logo/logo-string.png',
          height: 20,
          color: isIncognito ? Colors.white : null,
        ),
      ],
    );
  }
}
