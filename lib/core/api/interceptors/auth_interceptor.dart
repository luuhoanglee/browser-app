import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:browser_app/core/config/constants.dart';

import '../api_client.dart';
import '../decodable.dart';

extension Curl on RequestOptions {
  String toCurlCmd() {
    String cmd = "curl";

    String header = headers
        .map((key, value) {
          if (key == "content-type" &&
              value.toString().contains("multipart/form-data")) {
            value = "multipart/form-data;";
          }
          return MapEntry(key, "-H '$key: $value'");
        })
        .values
        .join(" ");
    String url = "$baseUrl$path";
    if (queryParameters.isNotEmpty) {
      String query = queryParameters
          .map((key, value) {
            return MapEntry(key, "$key=$value");
          })
          .values
          .join("&");

      url += (url.contains("?")) ? query : "?$query";
    }
    if (method == "GET") {
      cmd += " $header '$url'";
    } else {
      Map<String, dynamic> files = {};
      String postData = "-d ''";
      if (data != null) {
        if (data is FormData) {
          FormData fdata = data as FormData;
          for (var element in fdata.files) {
            MultipartFile file = element.value;
            files[element.key] = "@${file.filename}";
          }
          for (var element in fdata.fields) {
            files[element.key] = element.value;
          }
          if (files.isNotEmpty) {
            postData = files
                .map((key, value) => MapEntry(key, "-F '$key=$value'"))
                .values
                .join(" ");
          }
        } else if (data is Map<String, dynamic>) {
          files.addAll(data);

          if (files.isNotEmpty) {
            postData = "-d '${json.encode(files).toString()}'";
          }
        }
      }

      String method = this.method.toString();
      cmd += " -X $method $postData $header '$url'";
    }

    return cmd;
  }
}

class AuthToken implements Decoder<AuthToken> {
  String? accessToken;
  String? refreshToken;
  String? deviceHash;
  int? expiredTime;

  AuthToken(
      {this.accessToken, this.refreshToken, this.expiredTime, this.deviceHash});

  @override
  AuthToken decode(dynamic data) {
    expiredTime = data['expired_time'];
    return this;
  }

  Future startRefreshToken() async {
    await Future.delayed(const Duration(seconds: 5));
    // assign new access token
    accessToken = '';
  }

  bool isExpired() {
    return false;
  }
}

class AuthInterceptor extends InterceptorsWrapper {
  final APIClient client;
  AuthToken token;

  AuthInterceptor(this.client, this.token);

  @override
  Future onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final authorize = options.extra[RequestExtraKeys.authorize] ?? true;
    if (!authorize) {
      return super.onRequest(options, handler);
    }
    if (token.isExpired()) {
      // client.instance.lock();
      debugPrint('Lock request for refreshing token...');
      await token.startRefreshToken();
      // client.instance.unlock();
      debugPrint('Refresh token completed!');
    }
    if (token.accessToken != null) {
      options.headers['Authorization'] = 'Bearer ${token.accessToken}';
    }
    if (token.deviceHash != null) {
      options.headers["device_hash"] = token.deviceHash;
      options.headers["Device"] = token.deviceHash;
    }
    // final curl = options.toCurlCmd();
    // log("Curl: $curl");
    return super.onRequest(options, handler);
  }

// String cURLRepresentation(RequestOptions options) {
//   List<String> components = ["\$ curl -i"];
//   if (options.method.toUpperCase() == "GET") {
//     components.add("-X ${options.method}");
//   }
//
//   options.headers.forEach((k, v) {
//     if (k != "Cookie") {
//       components.add("-H \"$k: $v\"");
//     }
//   });
//
//   var data = jsonEncode(options.data);
//   data = data.replaceAll('"', '\\"');
//   components.add("-d \"$data\"");
//
//   components.add("\"${options.uri.toString()}\"");
//
//   return components.join('\\\n\t');
// }
}
