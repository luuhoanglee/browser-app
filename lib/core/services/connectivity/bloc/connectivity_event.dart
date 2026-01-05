import 'package:freezed_annotation/freezed_annotation.dart';

part 'connectivity_event.freezed.dart';

@freezed
class ConnectivityEvent with _$ConnectivityEvent {
  const factory ConnectivityEvent.initial() = Initial;
  const factory ConnectivityEvent.updateStatus([@Default(false) bool isDisconnect]) = UpdateStatus;
  const factory ConnectivityEvent.error(Object ex, StackTrace? stackTrace) = Error;
}