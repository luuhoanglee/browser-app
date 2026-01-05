// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connectivity_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ConnectivityEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isDisconnect) updateStatus,
    required TResult Function(Object ex, StackTrace? stackTrace) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(bool isDisconnect)? updateStatus,
    TResult? Function(Object ex, StackTrace? stackTrace)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isDisconnect)? updateStatus,
    TResult Function(Object ex, StackTrace? stackTrace)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(UpdateStatus value) updateStatus,
    required TResult Function(Error value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(UpdateStatus value)? updateStatus,
    TResult? Function(Error value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(UpdateStatus value)? updateStatus,
    TResult Function(Error value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConnectivityEventCopyWith<$Res> {
  factory $ConnectivityEventCopyWith(
          ConnectivityEvent value, $Res Function(ConnectivityEvent) then) =
      _$ConnectivityEventCopyWithImpl<$Res, ConnectivityEvent>;
}

/// @nodoc
class _$ConnectivityEventCopyWithImpl<$Res, $Val extends ConnectivityEvent>
    implements $ConnectivityEventCopyWith<$Res> {
  _$ConnectivityEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConnectivityEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
          _$InitialImpl value, $Res Function(_$InitialImpl) then) =
      __$$InitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$ConnectivityEventCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
      _$InitialImpl _value, $Res Function(_$InitialImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConnectivityEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitialImpl implements Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'ConnectivityEvent.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isDisconnect) updateStatus,
    required TResult Function(Object ex, StackTrace? stackTrace) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(bool isDisconnect)? updateStatus,
    TResult? Function(Object ex, StackTrace? stackTrace)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isDisconnect)? updateStatus,
    TResult Function(Object ex, StackTrace? stackTrace)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(UpdateStatus value) updateStatus,
    required TResult Function(Error value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(UpdateStatus value)? updateStatus,
    TResult? Function(Error value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(UpdateStatus value)? updateStatus,
    TResult Function(Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class Initial implements ConnectivityEvent {
  const factory Initial() = _$InitialImpl;
}

/// @nodoc
abstract class _$$UpdateStatusImplCopyWith<$Res> {
  factory _$$UpdateStatusImplCopyWith(
          _$UpdateStatusImpl value, $Res Function(_$UpdateStatusImpl) then) =
      __$$UpdateStatusImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool isDisconnect});
}

/// @nodoc
class __$$UpdateStatusImplCopyWithImpl<$Res>
    extends _$ConnectivityEventCopyWithImpl<$Res, _$UpdateStatusImpl>
    implements _$$UpdateStatusImplCopyWith<$Res> {
  __$$UpdateStatusImplCopyWithImpl(
      _$UpdateStatusImpl _value, $Res Function(_$UpdateStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConnectivityEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isDisconnect = null,
  }) {
    return _then(_$UpdateStatusImpl(
      null == isDisconnect
          ? _value.isDisconnect
          : isDisconnect // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$UpdateStatusImpl implements UpdateStatus {
  const _$UpdateStatusImpl([this.isDisconnect = false]);

  @override
  @JsonKey()
  final bool isDisconnect;

  @override
  String toString() {
    return 'ConnectivityEvent.updateStatus(isDisconnect: $isDisconnect)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateStatusImpl &&
            (identical(other.isDisconnect, isDisconnect) ||
                other.isDisconnect == isDisconnect));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isDisconnect);

  /// Create a copy of ConnectivityEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateStatusImplCopyWith<_$UpdateStatusImpl> get copyWith =>
      __$$UpdateStatusImplCopyWithImpl<_$UpdateStatusImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isDisconnect) updateStatus,
    required TResult Function(Object ex, StackTrace? stackTrace) error,
  }) {
    return updateStatus(isDisconnect);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(bool isDisconnect)? updateStatus,
    TResult? Function(Object ex, StackTrace? stackTrace)? error,
  }) {
    return updateStatus?.call(isDisconnect);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isDisconnect)? updateStatus,
    TResult Function(Object ex, StackTrace? stackTrace)? error,
    required TResult orElse(),
  }) {
    if (updateStatus != null) {
      return updateStatus(isDisconnect);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(UpdateStatus value) updateStatus,
    required TResult Function(Error value) error,
  }) {
    return updateStatus(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(UpdateStatus value)? updateStatus,
    TResult? Function(Error value)? error,
  }) {
    return updateStatus?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(UpdateStatus value)? updateStatus,
    TResult Function(Error value)? error,
    required TResult orElse(),
  }) {
    if (updateStatus != null) {
      return updateStatus(this);
    }
    return orElse();
  }
}

abstract class UpdateStatus implements ConnectivityEvent {
  const factory UpdateStatus([final bool isDisconnect]) = _$UpdateStatusImpl;

  bool get isDisconnect;

  /// Create a copy of ConnectivityEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateStatusImplCopyWith<_$UpdateStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
          _$ErrorImpl value, $Res Function(_$ErrorImpl) then) =
      __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Object ex, StackTrace? stackTrace});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$ConnectivityEventCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
      _$ErrorImpl _value, $Res Function(_$ErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConnectivityEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ex = null,
    Object? stackTrace = freezed,
  }) {
    return _then(_$ErrorImpl(
      null == ex ? _value.ex : ex,
      freezed == stackTrace
          ? _value.stackTrace
          : stackTrace // ignore: cast_nullable_to_non_nullable
              as StackTrace?,
    ));
  }
}

/// @nodoc

class _$ErrorImpl implements Error {
  const _$ErrorImpl(this.ex, this.stackTrace);

  @override
  final Object ex;
  @override
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'ConnectivityEvent.error(ex: $ex, stackTrace: $stackTrace)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            const DeepCollectionEquality().equals(other.ex, ex) &&
            (identical(other.stackTrace, stackTrace) ||
                other.stackTrace == stackTrace));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(ex), stackTrace);

  /// Create a copy of ConnectivityEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function(bool isDisconnect) updateStatus,
    required TResult Function(Object ex, StackTrace? stackTrace) error,
  }) {
    return error(ex, stackTrace);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function(bool isDisconnect)? updateStatus,
    TResult? Function(Object ex, StackTrace? stackTrace)? error,
  }) {
    return error?.call(ex, stackTrace);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function(bool isDisconnect)? updateStatus,
    TResult Function(Object ex, StackTrace? stackTrace)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(ex, stackTrace);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Initial value) initial,
    required TResult Function(UpdateStatus value) updateStatus,
    required TResult Function(Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Initial value)? initial,
    TResult? Function(UpdateStatus value)? updateStatus,
    TResult? Function(Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Initial value)? initial,
    TResult Function(UpdateStatus value)? updateStatus,
    TResult Function(Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class Error implements ConnectivityEvent {
  const factory Error(final Object ex, final StackTrace? stackTrace) =
      _$ErrorImpl;

  Object get ex;
  StackTrace? get stackTrace;

  /// Create a copy of ConnectivityEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
