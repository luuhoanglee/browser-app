import 'package:freezed_annotation/freezed_annotation.dart';
part 'connectivity_state.freezed.dart';

@freezed
class ConnectivityState with _$ConnectivityState {
  const factory ConnectivityState.started() = Started;
  const factory ConnectivityState.loaded([@Default(false) bool isDisconnect]) = Loaded;
}