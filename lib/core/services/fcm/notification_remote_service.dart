
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:browser_app/core/api/api_client.dart';
import 'package:browser_app/core/api/cubit/api_cubit.dart';

import 'package:browser_app/core/resources/app_info.dart';

class NotificationRemoteService {
  late APIClient apiClient;

  NotificationRemoteService() {
    apiClient = AppInfo.navigatorKey.currentContext!.read<ApiCubit>().apiClient;
  }
}