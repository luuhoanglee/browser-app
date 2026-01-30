import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:browser_app/core/api/cubit/api_cubit.dart';
import 'package:browser_app/core/extentions/datetime.dart';
import 'package:browser_app/core/logger/level.dart';
import 'package:browser_app/core/resources/app_info.dart';

class Logger {
  static void show(Object? message) {
    log('【Logger】- $message');
  }

  static void error(Object? error, [StackTrace? stack]) {
    log(
      '【${AppInfo.package?.packageName} - ${DateTime.now().format_yyyyMMdd_hhmmss}】 Error: $error',
      stackTrace: stack,
      level: Level.SEVERE.value,
    );
    if (!kIsWeb) {
      /// firebase crashlytics
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    AppInfo.navigatorKey.currentContext?.read<ApiCubit>().endFetch();
  }
}