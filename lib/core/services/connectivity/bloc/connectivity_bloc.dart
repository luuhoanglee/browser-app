import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:browser_app/core/logger/logger.dart';
import 'package:browser_app/core/services/connectivity/bloc/connectivity_event.dart';
import 'package:browser_app/core/services/connectivity/bloc/connectivity_state.dart';

export 'connectivity_event.dart';
export 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  ConnectivityBloc() : super((const ConnectivityState.started())) {
    on<UpdateStatus>(_onFetchData);
  }
  Future<void> _onFetchData(UpdateStatus event, Emitter<ConnectivityState> emit) async {
    bool isDisconnect = event.maybeWhen(
      updateStatus: (isDisconnect) => isDisconnect,
      orElse: () => false,
    );

    Logger.show('isDisconnect: $isDisconnect');

    emit(Loaded(isDisconnect));
  }
}