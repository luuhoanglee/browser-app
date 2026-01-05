import 'dart:async';
import 'package:flutter/foundation.dart';

class StreamListenable extends ChangeNotifier {
  late final StreamSubscription _sub;

  StreamListenable(Stream stream) {
    _sub = stream.listen((_) {
      notifyListeners(); // báo cho GoRouter refresh
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
