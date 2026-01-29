
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:browser_app/core/api/api_response.dart';
import 'package:browser_app/core/enum/api/api.dart' show SatrepsErrorType;

class ResponseInterceptor extends InterceptorsWrapper {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final result = APIResponse(response: response);
    if (result.hasError) {
      final error = ErrorResponse.fromSatreps(response);
      if (error.error == SatrepsErrorType.unauthorized) {
        handler.reject(
            DioException(
                requestOptions: response.requestOptions,
                response: response..statusCode = HttpStatus.unauthorized,
                type: DioExceptionType.badResponse),
            true);
        return;
      }
    }
     super.onResponse(response, handler);
  }
}
