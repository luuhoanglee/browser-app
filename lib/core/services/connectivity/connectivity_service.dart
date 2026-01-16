import 'dart:async' show StreamSubscription;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:browser_app/core/resources/app_info.dart';
import 'package:browser_app/core/services/connectivity/bloc/connectivity_bloc.dart';

class ConnectivityService {
  static ConnectivityService? _instance;

  static ConnectivityService get instance {
    _instance ??= ConnectivityService();
    return _instance!;
  }

  void dispose() => _subscription.cancel();
  void resume() => _subscription.resume();
  void pause() => _subscription.pause();
  void initial() => _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
    bool isDisConnect = result.any((c) => c == ConnectivityResult.none);
    // Todo: Handle disconnect network
    if (AppInfo.navigatorKey.currentContext != null) {
      AppInfo.navigatorKey.currentContext!
          .read<ConnectivityBloc>()
          .add(UpdateStatus(isDisConnect));
    }
  });

  late StreamSubscription<List<ConnectivityResult>> _subscription;
}