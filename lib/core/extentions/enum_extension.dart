import 'package:satreps_client_app/core/interface/has_value.dart';

extension EnumLabel on Enum {
  String get label {
    if (this is HasValue) return (this as HasValue).value;
    return name;
  }
}
