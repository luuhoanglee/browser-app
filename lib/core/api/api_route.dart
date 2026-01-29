import 'package:dio/dio.dart';
import 'package:browser_app/core/config/constants.dart' show RequestExtraKeys;
import 'package:browser_app/core/enum/api/api.dart' show APIType;

class APIRoute implements APIRouteConfigurable {
  final APIType type;

  ///you can override the base url here
  final String? baseUrl;
  final String? routeParams;
  final String? method;

  final String _auth = "/auth";

  APIRoute(this.type, {this.baseUrl, this.routeParams, this.method});

  /// Return config of api (method, url, header)
  @override
  RequestOptions? getConfig(BaseOptions baseOption) {
    final authorize = {RequestExtraKeys.authorize: true};
    String method = APIMethod.get, path = "";
    const responseType = ResponseType.json;
    switch (type) {
      case APIType.login:
        path = "/users/login";
        method = APIMethod.post;
        authorize[RequestExtraKeys.authorize] = false;
        break;

    }
    final options = Options(extra: authorize, responseType: responseType, method: method)
    .compose(
      baseOption,
      path,
    );
    if (baseUrl != null) {
      options.baseUrl = baseUrl!;
    }
    return options;
  }
}

// ignore: one_member_abstracts
abstract class APIRouteConfigurable {
  RequestOptions? getConfig(BaseOptions baseOption);
}

class APIMethod {
  static const get = 'get';
  static const post = 'post';
  static const put = 'put';
  static const patch = 'patch';
  static const delete = 'delete';
}