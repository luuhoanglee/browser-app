import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:satreps_client_app/core/services/locale/locale_service.dart';

class LocaleCubit extends Cubit<Locale> {
  late LocaleService localeService;

  LocaleCubit() : super(LocaleService.es) {
    localeService = LocaleService();
    _loadLocale();
  }

  convertFullDate({required DateTime date}) {
    var formatted = DateFormat("EEEE d ${state.languageCode == 'es' ? "'de'" : ''} MMMM, y", '${state.languageCode}_${state.countryCode ?? ''}').format(date);
    formatted = formatted.replaceFirstMapped(
      RegExp(r' de ([a-záéíóúñ]+),'),
          (match) {
        final month = match.group(1)!;
        final capitalized = '${month[0].toUpperCase()}${month.substring(1)}';
        return ' de $capitalized,';
      },
    );

    formatted = '${formatted[0].toUpperCase()}${formatted.substring(1)}';
    return formatted;
  }

  convertFullDateYYYYMMDD({required DateTime date}) {
    var formatted = DateFormat("d ${state.languageCode == 'es' ? "'de'" : ''} MMMM, y", '${state.languageCode}_${state.countryCode ?? ''}').format(date);
    formatted = formatted.replaceFirstMapped(
      RegExp(r' de ([a-záéíóúñ]+),'),
          (match) {
        final month = match.group(1)!;
        final capitalized = '${month[0].toUpperCase()}${month.substring(1)}';
        return ' de $capitalized,';
      },
    );

    formatted = '${formatted[0].toUpperCase()}${formatted.substring(1)}';
    return formatted;
  }

  convertDate({required DateTime date}) {
    var formatted = DateFormat("EEEE, d ${state.languageCode == 'es' ? "'de'" : ''} MMMM", '${state.languageCode}_${state.countryCode ?? ''}').format(date);
    formatted = formatted.replaceFirstMapped(
      RegExp(r' de ([a-záéíóúñ]+)'),
          (match) {
        final month = match.group(1)!;
        final capitalized = '${month[0].toUpperCase()}${month.substring(1)}';
        return ' de $capitalized';
      },
    );

    formatted = '${formatted[0].toUpperCase()}${formatted.substring(1)}';
    return formatted;
  }

  Future<void> _loadLocale() async {
    final locale = await localeService.loadLocale() ?? LocaleService.es;
    await initializeDateFormatting('${locale.languageCode}_${locale.countryCode ?? ''}', null);
    emit(locale);
  }

  Future<void> setLocale(Locale locale) async {
    await localeService.setLocale(locale);
    await initializeDateFormatting('${locale.languageCode}_${locale.countryCode ?? ''}', null);
    emit(locale);
  }
}
