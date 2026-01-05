import 'package:intl/intl.dart' show DateFormat;
import 'package:satreps_client_app/core/extentions/datetime.dart';

extension EXString on String {
  String get convertToAmPm => DateFormat("hh:mm a", "en")
    .format(DateFormat("HH:mm").parse(this))
    .replaceAll("AM", "A.M.").replaceAll("PM", "P.M.");

  DateTime convertDate([DateTime? date]) => date == null
    ? DateTime.parse(this)
    : DateFormat("yyyy-MM-dd HH:mm").parse('${date.format_yyyyMMdd} $this');
}