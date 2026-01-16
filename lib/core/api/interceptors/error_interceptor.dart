import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:browser_app/core/config/constants.dart';
import 'package:browser_app/core/logger/logger.dart';
import 'package:browser_app/core/resources/app_colors.dart';
import 'package:browser_app/core/resources/app_info.dart';
import 'package:browser_app/core/routes/route_cubit.dart';
import 'package:sizer/sizer.dart';

import '../api_client.dart';

class ErrorInterceptor extends InterceptorsWrapper {
  APIClient apiClient;
  Function unauthorizedCallback;
  Function(DioErrorType errorType)? onErrorCallback;
  Function(DioError error)? onNetworkErrorCallback;
  bool hasUnAuthorizeBefore=false;
  ErrorInterceptor(this.apiClient,
      {required this.unauthorizedCallback,
      this.onErrorCallback,
      this.onNetworkErrorCallback});
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if(hasUnAuthorizeBefore)hasUnAuthorizeBefore=false;
    super.onResponse(response, handler);

  }
  @override
  void onError(DioError error, ErrorInterceptorHandler handler) async {
    switch (error.type) {
      case DioErrorType.cancel:
      case DioErrorType.connectTimeout:
      case DioErrorType.sendTimeout:
      case DioErrorType.receiveTimeout:
        if (onErrorCallback != null) {
          onErrorCallback!(error.type);
        }
        break;
      case DioErrorType.other:
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
      case DioErrorType.response:
        ///Unauthorized, may be the access token has been expired
        if (error.response!.statusCode == HttpStatus.unauthorized &&
            error.requestOptions
                    .extra[AppConstants.ignoreNavigateWhenUnAuthorize] !=
                true && !hasUnAuthorizeBefore) {
          hasUnAuthorizeBefore=true;
          apiClient.instance.lock();
          unauthorizedCallback();
          AppInfo.navigatorKey.currentContext!.read<RouteCubit>().logout();
        }
        if (error.response!.statusCode == HttpStatus.tooManyRequests) {
          Fluttertoast.showToast(
            msg: "Has enviado demasiadas solicitudes.\nPor favor, inténtalo de nuevo más tarde.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.redAccent,
            textColor: AppColors.white,
            fontSize: 16.0.px,
          );
        }

        break;
    }
    super.onError(error, handler);
  }

// Future<Response> _handleOfflineRequest(DioError error) async {
//   var offlineCompleter = Completer<Response>();
//   Connectivity().onConnectivityChanged.listen((connectionState) async {
//     if (connectionState != ConnectivityResult.none) {
//       apiClient.dio.unlock();
//       final response = await apiClient.dio.fetch(error.requestOptions);
//       if (response != null) {
//         offlineCompleter.complete(response);
//       } else {
//         offlineCompleter.completeError(DioErrorType.other);
//       }
//       offlineCompleter = Completer();
//     }
//   });
//   return offlineCompleter.future;
// }

// _checkConnection(DioError error) {
//   return error.type == DioErrorType.other &&
//       error.error != null &&
//       error.error is SocketException;
// }
}
