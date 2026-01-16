import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:browser_app/core/api/api_client.dart';
import 'package:browser_app/core/api/api_response.dart';
import 'package:browser_app/core/api/api_route.dart';
import 'package:browser_app/core/api/cubit/api_cubit.dart';

import 'package:browser_app/core/enum/api/api.dart';
import 'package:browser_app/core/logger/logger.dart';
import 'package:browser_app/core/resources/app_info.dart';
import 'package:browser_app/features/notification/data/model/notification/notification_model.dart';

class NotificationRemoteService {
  late APIClient apiClient;

  NotificationRemoteService() {
    apiClient = AppInfo.navigatorKey.currentContext!.read<ApiCubit>().apiClient;
  }

  Future<bool> createDevice({required String tokenFCM}) async {
    try {
      final response = await apiClient.request(
        route: APIRoute(APIType.createDeviceFCM),
        body: {
          'platform': kIsWeb ? 'web' : Platform.isIOS ? 'ios' : 'android',
          'token': tokenFCM,
        },
        create: (response) => APIResponse(
          response: response,
        ),
      );
      return response.decodedData != null;
    } catch (e, s) {
      Logger.error('Error load createDevice: $e', s);
      return false;
    }
  }

  Future<bool> disableDevice({required String tokenFCM}) async {
    try {
      final response = await apiClient.request(
        route: APIRoute(APIType.disableDeviceFCM),
        body: {
          'token': tokenFCM,
        },
        create: (response) => APIResponse<bool>(
          response: response,
        ),
      );
      return response.decodedData ?? false;
    } catch (e, s) {
      Logger.error('Error load disableDevice: $e', s);
      return false;
    }
  }

  Future<List<NotificationModel>> getList() async {
    try {
      final response = await apiClient.request(
        route: APIRoute(APIType.getNotify),
        create: (response) => APIListResponse<NotificationModel>(
          response: response,
          createObject: const NotificationModel()
        ),
      );
      return response.decodedData ?? [];
    } catch (e, s) {
      Logger.error('Error load getList notification: $e', s);
      return [];
    }
  }
}