import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:browser_app/core/resources/app_info.dart';
import 'package:browser_app/core/services/locale/locale_cubit.dart';
import 'package:timeago/timeago.dart' as timeago;

extension EXDatetime on DateTime {
  String get to_yyyyMMdd => '$year$month$day';
  String get to_hhmmss => '$hour$minute$second';
  String get format_yyyyMMdd => '$year-$month-$day';
  String get format_yyyyMMdd_hhmmss => '$year-$month-$day $hour:$minute:$second';
  String get format_hhmmss => '$hour:$minute:$second';
  String get toAgo => timeago.format(this);

  String get fullDateLocale => AppInfo.navigatorKey.currentContext?.read<LocaleCubit>().convertFullDate(date: this) ?? '';
  String get fullDateLocaleYYYYMMDD => AppInfo.navigatorKey.currentContext?.read<LocaleCubit>().convertFullDateYYYYMMDD(date: this) ?? '';
  String get dateLocale => AppInfo.navigatorKey.currentContext?.read<LocaleCubit>().convertDate(date: this) ?? '';
}