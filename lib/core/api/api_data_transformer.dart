import 'package:dio/dio.dart';

///R = Raw type you get from response ( Ex: Using DIO is Response object)
///E = Expected type ( Ex: Common data format you want to get is Map<String,dynamic>
abstract class BaseAPIResponseDataTransformer<R, E> {
  E extractData(R response);
}

class DioResponseDataTransformer
    extends BaseAPIResponseDataTransformer<Response, Map<String, dynamic>> {
  @override
  Map<String, dynamic> extractData(Response response) {
    return response.data is Map ? response.data : {
      "data":response.data
    };
  }
}

class SatrepsFormatDataTransformer extends BaseAPIResponseDataTransformer<
    Map<String, dynamic>, Map<String, dynamic>> {
  @override
  Map<String, dynamic> extractData(Map<String, dynamic> response) {
    var result = response["result"];
    int? statusCode = response['statusCode'];
    var data;
    bool hasError = false;
    if (result != null) {
      data = result;
    }
    if (statusCode is num && statusCode != 200 || result ==null) {
      hasError = true;
    }
    return {
      "status": statusCode ,
      "data": data,
      "hasError": hasError,
    };
  }
}
