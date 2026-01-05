import 'dart:io' show SocketException;
import 'package:dio/dio.dart' show DioError;

abstract class ApiState {}

class InitialState extends ApiState {}
class LoadingState extends ApiState {}
class SuccessState extends ApiState {}
class UnAuthorize extends ApiState {}
class TimeOutRequest extends ApiState {}
class NoFoundNetwork extends ApiState {
  DioError? error;

  NoFoundNetwork({
    this.error,
  });

  bool isServerUnderMaintenance() {
    if (error != null) {
      if (error!.error is SocketException) {
        SocketException ex = error!.error as SocketException;
        if (ex.address != null) {
          return true;
        }
      }
    }
    return false;
  }
}