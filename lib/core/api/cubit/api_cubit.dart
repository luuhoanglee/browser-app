import 'package:curl_logger_dio_interceptor/curl_logger_dio_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:browser_app/core/api/api_client.dart';
import 'package:browser_app/core/api/cubit/api_state.dart';
import 'package:browser_app/core/api/interceptors/auth_interceptor.dart';
import 'package:browser_app/core/api/interceptors/error_interceptor.dart';
import 'package:browser_app/core/api/interceptors/log_interceptor.dart';
import 'package:browser_app/core/api/interceptors/response_interceptor.dart';
import 'package:browser_app/core/shared/cache/cache_key.dart';
import 'package:browser_app/core/shared/cache/cache_manager.dart';

class ApiCubit extends Cubit<ApiState> {
  ApiCubit(super.initialState) {
    initInterceptors();
  }

  void startFetch() {
    emit(LoadingState());
  }
  void endFetch() {
    emit(SuccessState());
  }

  APIClient apiClient = APIClient();

  Future<String?> getToken() async {
    if (apiClient.instance.interceptors.isEmpty) {
      return null;
    }

    final cacheManager = CacheManager<String>(keyData: CacheKey.loginToken);
    String? tokenCache = await cacheManager.get();

    final authInterceptor = apiClient.instance.interceptors.first as AuthInterceptor;
    return authInterceptor.token.accessToken ?? tokenCache;
  }

  void initInterceptors({String? accessToken, String? deviceHash}) {
    AuthToken? localAuthToken;
    if (apiClient.instance.interceptors.isNotEmpty) {
      final authInterceptor = apiClient.instance.interceptors.first as AuthInterceptor;
      localAuthToken = authInterceptor.token;
      apiClient.instance.interceptors.clear();
    }

    ///auth token is always the firs interceptor for easily searching
    final AuthToken authToken = localAuthToken ?? AuthToken();
    if (accessToken != null) {
      authToken.accessToken = accessToken;
    } else {
      String? accessToken = CacheManager.getValue<String>(CacheKey.loginToken);
      if (accessToken != null) {
        authToken.accessToken = accessToken;
      }
    }
    if (deviceHash != null) {
      authToken.deviceHash = deviceHash;
    }
    final AuthInterceptor authInterceptor = AuthInterceptor(apiClient, authToken);
    apiClient.instance.interceptors.add(authInterceptor);
    apiClient.instance.interceptors.addAll([
      if (!kReleaseMode) LogInterceptor(responseBody: true, requestBody: true, responseHeader: false),
      if (!kReleaseMode) CurlLoggerDioInterceptor(printOnSuccess: true),
      ErrorInterceptor(apiClient, unauthorizedCallback: onLogout, onErrorCallback: onErrorCallback, onNetworkErrorCallback: onNetworkErrorCallback),
      ResponseInterceptor(),
      if (!kReleaseMode) APILogInterceptor(),
    ]);
  }

  void onNetworkErrorCallback(DioError error) {
    emit(NoFoundNetwork(error: error));
  }

  void onErrorCallback(DioErrorType type) {
    if (type == DioErrorType.connectTimeout || type == DioErrorType.receiveTimeout || type == DioErrorType.sendTimeout) {
      emit(TimeOutRequest());
    }
  }

  void onLogout() {
    emit(UnAuthorize());
  }

}