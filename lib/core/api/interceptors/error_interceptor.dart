import 'dart:io';

import 'package:dio/dio.dart';
import 'package:browser_app/core/config/constants.dart';

import '../api_client.dart';

class ErrorInterceptor extends InterceptorsWrapper {
  APIClient apiClient;
  Function unauthorizedCallback;
  Function(DioExceptionType errorType)? onErrorCallback;
  Function(DioException error)? onNetworkErrorCallback;
  bool hasUnAuthorizeBefore = false;

  ErrorInterceptor(this.apiClient,
      {required this.unauthorizedCallback,
        this.onErrorCallback,
        this.onNetworkErrorCallback});

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (hasUnAuthorizeBefore) hasUnAuthorizeBefore = false;
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    switch (error.type) {
      case DioExceptionType.cancel:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        if (onErrorCallback != null) {
          onErrorCallback!(error.type);
        }
        break;
      case DioExceptionType.unknown:
      // final isOffline = _checkConnection(error);
      // Response response;
      // if (isOffline) {
      //   response = await _handleOfflineRequest(error);
      // } else {
      //   response = error.response;
      // }
        if (onNetworkErrorCallback != null && error.error is SocketException) {
          onNetworkErrorCallback!(error);
        }
        break;
      case DioExceptionType.badResponse:

      ///Unauthorized, may be the access token has been expired
        if (error.response!.statusCode == HttpStatus.unauthorized &&
            error.requestOptions
                .extra[AppConstants.ignoreNavigateWhenUnAuthorize] !=
                true && !hasUnAuthorizeBefore) {
          hasUnAuthorizeBefore = true;
          unauthorizedCallback();
        }
        if (error.response!.statusCode == HttpStatus.tooManyRequests) {

        }

        break;
      case DioExceptionType.badCertificate:
      // TODO: Handle this case.
        throw UnimplementedError();
      case DioExceptionType.connectionError:
      // TODO: Handle this case.
        throw UnimplementedError();
    }
    super.onError(error, handler);
  }
}
