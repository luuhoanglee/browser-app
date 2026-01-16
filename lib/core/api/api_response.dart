import 'dart:io';

import 'package:dio/dio.dart';
import 'package:browser_app/core/enum/api/api.dart' show SatrepsErrorType;

import 'api_data_transformer.dart';
import 'decodable.dart';

typedef T GenericObject<T>(_);

///T Original response type
abstract class BaseAPIResponseWrapper<R, E> {
  R? originalResponse;
  E? decodedData;

  ///For default, any response should have it
  int? status, count;
  bool hasError = false;

  ///For response from Satreps BE
  String? type;

  BaseAPIResponseDataTransformer? dataTransformer;

  BaseAPIResponseWrapper({this.originalResponse, this.dataTransformer});

  Map<String, dynamic> extractJson() => dataTransformer != null
      ? dataTransformer!.extractData(originalResponse)
      : {};

  void decode(Map<String, dynamic> formatResponse, {dynamic createObject}) {
    status = formatResponse["status"];
    hasError = formatResponse["hasError"];
    type = formatResponse["type"];
    count = formatResponse["count"];
  }
}

class APIResponse<T> extends BaseAPIResponseWrapper<Response, T> {
  APIResponse({T? createObject, Response? response})
      : super(
            originalResponse: response,
            dataTransformer: DioResponseDataTransformer()) {
    ///Step 1: get raw json
    final decodableData = extractJson();

    ///Step 2:  format raw json with our style
    final formatData = SatrepsFormatDataTransformer().extractData(decodableData);

    ///Finally, we parse it to object, you can pass the createObject
    ///to parse them with field data
    decode(formatData, createObject: createObject);
  }

  @override
  void decode(Map<String, dynamic> formatResponse, {createObject}) {
    super.decode(formatResponse, createObject: createObject);
    if (createObject is Decoder && !hasError) {
      decodedData = createObject.decode(formatResponse["data"]);
    } else if (T == dynamic) {
      decodedData = formatResponse["data"];
    } else {
      final data = formatResponse["data"];
      if (data is T) decodedData = data;
    }
  }
}

class APICountNotificationResponse
    extends BaseAPIResponseWrapper<Response, dynamic> {
  APICountNotificationResponse(Response? response)
      : super(
            originalResponse: response,
            dataTransformer: DioResponseDataTransformer()) {
    ///Step 1: get raw json
    final decodableData = extractJson();

    ///Step 2:  format raw json with our style
    final formatData = SatrepsFormatDataTransformer().extractData(decodableData);

    ///Finally, we parse it to object, you can pass the createObject
    ///to parse them with field data
    decode(formatData);
  }
}

class APIListResponse<T> extends BaseAPIResponseWrapper<Response, List<T>> {
  APIListResponse({T? createObject, Response? response})
      : super(
            originalResponse: response,
            dataTransformer: DioResponseDataTransformer()) {
    final decodableData = extractJson();
    final formatData = SatrepsFormatDataTransformer().extractData(decodableData);
    decode(formatData, createObject: createObject);
  }

  @override
  void decode(Map<String, dynamic> formatResponse, {createObject}) {
    super.decode(formatResponse, createObject: createObject);
    if (createObject is Decoder && !hasError) {
      final data = formatResponse["data"];
      if (data is List && data.isNotEmpty) {
        decodedData ??= <T>[];
        for (final e in data) {
          (decodedData as List).add(createObject.decode(e));
        }
      }
      decodedData ??= <T>[];
    }
  }
}

class ErrorResponse extends BaseAPIResponseWrapper<Response, dynamic> {
  String? message;
  late SatrepsErrorType error;
  DioError? dioError;

  ErrorResponse.fromSatreps(Response? originalResponse)
      : super(
            originalResponse: originalResponse,
            dataTransformer: DioResponseDataTransformer()) {
    final decodableData = extractJson();
    final formatData = SatrepsFormatDataTransformer().extractData(decodableData);
    decode(formatData);
  }

  @override
  void decode(Map<String, dynamic> formatResponse, {createObject}) {
    super.decode(formatResponse);
    final data = formatResponse["data"];
    decodedData = data;
    if (decodedData is String) {
      message = decodedData;
    } else {
      // get error message from response
      message ??= formatResponse["message"] ?? "Error";
    }
    error = getErrorType(type);
  }

  ErrorResponse.fromDefault(Response? originalResponse, {this.dioError})
      : super(
            originalResponse: originalResponse,
            dataTransformer: DioResponseDataTransformer()) {
    error = getErrorType(originalResponse?.statusMessage);
    hasError = true;
    message = type = originalResponse?.data['message'];
    status = originalResponse?.statusCode;
  }

  ErrorResponse.fromSystem(this.error, this.message) {
    hasError = true;
    type = message;
    status = 400;
  }

  SatrepsErrorType getErrorType(String? type) {
    if (type == "access_token") {
      return SatrepsErrorType.unauthorized;
    } else if (type == "NOT FOUND") {
      return SatrepsErrorType.notFound;
    } else if (type == "missing_error") {
      return SatrepsErrorType.noFoundUser;
    } else if (type == "access_token_not_found") {
      return SatrepsErrorType.accessTokenNotFound;
    } else if (type == "missing_error") {
      return SatrepsErrorType.missingError;
    } else if (type == "verify_device") {
      return SatrepsErrorType.verifyDevice;
    }
    return SatrepsErrorType.unknown;
  }

  bool isNetworkError() {
    return dioError != null && dioError?.response == null && dioError!.error is SocketException && (dioError!.error as SocketException).address == null;
  }

  bool isServerUnderMaintenance() {
    return dioError != null && ((dioError?.response?.statusCode == 502)
        || ( dioError?.response == null && dioError!.error is SocketException && (dioError!.error as SocketException).address != null ));
  }

  @override
  String toString() {
    // TODO: implement toString
    return message ?? '';
  }
}