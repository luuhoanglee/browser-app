import 'package:dio/dio.dart';
import 'package:satreps_client_app/core/config/constants.dart' show RequestExtraKeys;
import 'package:satreps_client_app/core/enum/api/api.dart' show APIType;

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
      case APIType.createKeypair:
        path = "/users/create-keypair";
        method = APIMethod.post;
        break;
      case APIType.fetchKeypair:
        path = "/users/fetch-keypair";
        method = APIMethod.get;
        break;
      case APIType.sendSignEvent:
        path = "/users/verify-signin-event";
        method = APIMethod.post;
        break;
      case APIType.register:
        path = "/users/create";
        method = APIMethod.post;
        authorize[RequestExtraKeys.authorize] = false;
        break;
      case APIType.checkEmail:
        path = "/users/check-email";
        method = APIMethod.get;
        authorize[RequestExtraKeys.authorize] = false;
        break;
      case APIType.createRanch:
        path = "/ranches/create";
        method = APIMethod.post;
        break;
      case APIType.editRanch:
        path = "/ranches/edit";
        method = APIMethod.put;
        break;
      case APIType.deleteRanch:
        path = "/ranches/delete";
        method = APIMethod.delete;
        break;
      case APIType.loadRanches:
        path = "/ranches/get-by-organization";
        method = APIMethod.get;
        break;
      case APIType.loadMultiRanchOrg:
        path = "/organizations/get";
        method = APIMethod.get;
        break;
      case APIType.editMultiRanchOrg:
        path = "/organizations/edit";
        method = APIMethod.put;
        break;
      case APIType.loadUserMember:
        path = "/farmer/get-by-organization";
        method = APIMethod.get;
        break;
      case APIType.findUserMember:
        path = "/farmer/find";
        method = APIMethod.get;
        break;
      case APIType.createEvent:
        path = "/events/create";
        method = APIMethod.post;
        break;
      case APIType.createMember:
        path = "/farmer/create";
        method = APIMethod.post;
        break;
      case APIType.editMember:
        path = "/farmer/edit";
        method = APIMethod.put;
        break;
      case APIType.deleteMember:
        path = "/farmer/delete";
        method = APIMethod.delete;
        break;
      case APIType.registerMemberInfo:
        path = "/farmer/register";
        method = APIMethod.put;
        authorize[RequestExtraKeys.authorize] = false;
        break;
      case APIType.createDeviceFCM:
        path = "/notifications/register-device";
        method = APIMethod.post;
        break;
      case APIType.disableDeviceFCM:
        path = "/notifications/disable-device";
        method = APIMethod.put;
        break;
      case APIType.getNotify:
        path = "/notifications/get-by-user";
        method = APIMethod.get;
        break;
      case APIType.getStatusCertByInspector:
        path = "/certifications/get-status-by-inspector";
        method = APIMethod.get;
        break;
      case APIType.getSchedules:
        path = "/schedule/get-schedules";
        method = APIMethod.get;
        break;
      case APIType.setSchedules:
        path = "/schedule/set-schedules";
        method = APIMethod.post;
        break;
      case APIType.uploadImages:
        path = "/file/upload";
        method = APIMethod.put;
        break;
      case APIType.completeUpload:
        path = "/file/upload/complete";
        method = APIMethod.post;
        break;
      case APIType.geoLocation:
        path = '/geo-locations';
        method = APIMethod.get;
        break;
      case APIType.getInviteInfo:
        path = '/users/get-invite';
        method = APIMethod.get;
        break;
      case APIType.getMobilization:
        path = '/animals/timeline';
        method = APIMethod.get;
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

    if (type == APIType.completeUpload) {
      options.receiveTimeout = 20000;
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