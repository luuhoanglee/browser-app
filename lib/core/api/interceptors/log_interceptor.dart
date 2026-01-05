import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';

import 'package:satreps_client_app/core/api/interceptors/auth_interceptor.dart';

class APILogInterceptor extends InterceptorsWrapper {
  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    debugPrint('# ERROR');
    debugPrint('<-- ${err.response?.statusCode} - ${err.requestOptions.uri}');
    debugPrint('Message: ${err.error}');
    debugPrint('<-- END HTTP');
    return super.onError(err, handler);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log(options.toCurlCmd(),name: "CURL");
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('');
    debugPrint('# RESPONSE');
    debugPrint('<-- ${response.statusCode} - ${response.requestOptions.uri}');
    debugPrint('Response: ${response.data}');
    debugPrint('<-- END HTTP');
    return super.onResponse(response, handler);
  }
}
