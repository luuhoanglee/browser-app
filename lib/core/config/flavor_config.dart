import 'package:flutter/material.dart';
import 'package:browser_app/core/enum/flavor/flavor.dart' show Flavor;

class FlavorValues {
  final String? baseUrl;
  final String? baseFrontendUrl;
  final String? secretKey;
  final String? whatsappBaseUrl;
  final String? whatsappAccessToken;
  final String? whatsappPhoneNumberId;
  final String? whatsappTemplateName;
  final String? whatsappTemplateLanguage;
  final String? whatsappTemplateButtonType;
  final int? whatsappTemplateButtonIndex;
  final String? whatsappTemplateButtonParamTemplate;
  final String? webClientId;
  
  FlavorValues({
    @required this.baseUrl,
    @required this.secretKey,
    this.baseFrontendUrl,
    this.whatsappBaseUrl,
    this.whatsappAccessToken,
    this.whatsappPhoneNumberId,
    this.whatsappTemplateName,
    this.whatsappTemplateLanguage,
    this.whatsappTemplateButtonType,
    this.whatsappTemplateButtonIndex,
    this.whatsappTemplateButtonParamTemplate,
    this.webClientId
  });
}

class FlavorConfig {
  
  final Flavor flavor;
  final FlavorValues values;
  static FlavorConfig? instance;

  factory FlavorConfig({required Flavor flavor, required FlavorValues values}) {
    instance ??= FlavorConfig._internal(flavor, values);
    return instance!;
  }

  FlavorConfig._internal(this.flavor, this.values);

}
