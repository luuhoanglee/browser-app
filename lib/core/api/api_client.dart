import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:browser_app/core/api/api_response.dart' show GenericObject, BaseAPIResponseWrapper, ErrorResponse, SatrepsErrorType;
import 'package:browser_app/core/api/api_route.dart' show APIRouteConfigurable;
import 'package:browser_app/core/config/constants.dart' show AppConstants;
import 'package:browser_app/core/config/flavor_config.dart' show FlavorConfig;
import 'package:browser_app/core/enum/api/api.dart' show SatrepsErrorType;
import 'package:browser_app/core/logger/logger.dart';

abstract class BaseAPIClient {
  Future<T> request<T>(
      {required APIRouteConfigurable route,
      required GenericObject<T> create,
      Map<String, dynamic>? params,
      String? extraPath,
      bool noEncode = false,
      bool ignoreNavigateWhenUnAuthorize = false,
      Map<String, dynamic> header,
      Map<String, dynamic>? body});
}

class APIClient implements BaseAPIClient {
  static final APIClient shared = APIClient._internal();
  late BaseOptions options;
  late Dio instance;

  factory APIClient() {
    return shared;
  }

  factory APIClient.init() {
    return APIClient._internal();
  }

  APIClient._internal() {
    options = BaseOptions(
      baseUrl: "${FlavorConfig.instance?.values.baseUrl}/api",
      headers: {"Content-Type": "application/json"},
      receiveTimeout: 9000,
      responseType: ResponseType.json,
      validateStatus: (code) {
        if (code! <= 201) return true;
        return false;
      },
    );
    instance = Dio(options);
  }

  @override
  Future<T> request<T>(
      {required APIRouteConfigurable route,
      required GenericObject<T> create,
      Map<String, dynamic>? params,
      bool noEncode = false,
      bool ignoreNavigateWhenUnAuthorize = false,
      Map<String, dynamic>? header,
      String? extraPath,
      Map<String, dynamic>? body,
        bool useParamsKey = false,
        bool useFormData = false,
        ResponseType? responseType,
      }) async {
    final RequestOptions? requestOptions = route.getConfig(options);

    if (requestOptions != null) {
      if (params != null) {
        requestOptions.queryParameters = params.map((key, value) {
          if (value != String && value is! String) {
            String encodedValue = jsonEncode(value);
            if (noEncode) {
              final remove1 = RegExp(r"\\+");
              final remove2 = RegExp(r'\"(?=[\(])|(?<=[\)!])"');
              encodedValue = encodedValue.replaceAll(remove1, "");
              encodedValue = encodedValue.replaceAll(remove2, "");
              return MapEntry(key, encodedValue);
            }
            return MapEntry(key, encodedValue);
          }
          return MapEntry(key, value);
        });
        Logger.show('requestOptions.queryParameters: ${requestOptions.queryParameters}' );
      }
      if (extraPath != null) requestOptions.path += extraPath;
      requestOptions.extra[AppConstants.ignoreNavigateWhenUnAuthorize] =
          ignoreNavigateWhenUnAuthorize;
      if (header != null) requestOptions.headers.addAll(header);
      if (body != null) {
        final bodyData = body..removeWhere((k, v) => v == null);

        if(useParamsKey){
          if(useFormData){
            requestOptions.data = FormData.fromMap({"params": bodyData});
          }
          else{
            requestOptions.data = {"params": bodyData};
          }
        }
        else{
          if(useFormData){
            requestOptions.data = FormData.fromMap(bodyData);
          }
          else{
            requestOptions.data =  bodyData;
          }
        }
      } else {
        requestOptions.data = {"params": {}};
      }
      if(responseType!=null) requestOptions.responseType = responseType;

      try {
        Response response = await instance.fetch(requestOptions);
        T apiWrapper = create(response);
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (apiWrapper is BaseAPIResponseWrapper) {
            if (apiWrapper.hasError) throw ErrorResponse.fromSatreps(response);
            return apiWrapper;
          }

          ///If you want to use another object type such as primitive type, but you need to ensure that the response type will match your expected type
          if (response.data is T) {
            return response.data;
          } else {
            throw ErrorResponse.fromSystem(SatrepsErrorType.unknown,
                "Can not match the $T type with ${response.data.runtimeType}");
          }
        }
        throw ErrorResponse.fromDefault(response);
      } on DioError catch (e) {
        throw ErrorResponse.fromDefault(e.response, dioError: e);
      } catch (e, st) {
        Logger.show('$e, $st');
        if (e is ErrorResponse) {
          rethrow;
        } else {
          throw ErrorResponse.fromSystem(
              SatrepsErrorType.unknown, "Unknown Error");
        }
      }
    } else {
      throw ErrorResponse.fromSystem(
          SatrepsErrorType.unknown, "Missing request options");
    }
  }
}
