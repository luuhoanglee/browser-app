import 'package:browser_app/core/extentions/translate_string.dart';

class RequestExtraKeys {
  static const String authorize = 'Authorize';
}

class AppConstants {
  static const String ignoreNavigateWhenUnAuthorize =
      "IgnoreNavigateWhenUnAuthorize";
}

class AssessmentQuestions {
  static List<String> get titleStep => [
    'Manejo de potreros y alimentación animal'.tr,
    'Sanidad animal'.tr,
    'Registros e identificación'.tr,
    'Bienestar animal'.tr,
    'Personal'.tr,
    'Información adicional'.tr,
    'Resumen del formulario de inspección'.tr
  ];

  static List<List<String>> get assessmentQuestions => [
    assessmentQuestions1,
    assessmentQuestions2,
    assessmentQuestions3,
    assessmentQuestions4,
    assessmentQuestions5,
  ];

  static List<String> get assessmentQuestions1 => [
    '¿Los animales son alimentados 100% a base de pasturas?'.tr,
    '¿Los bovinos reciben suplementación con sales mineralizadas que cuentan con registro ICA?'.tr,
    '¿Los animales reciben suplementación con granos (Maiz, millo, Soya, cebada, tortas de Palmiste, arroz u otros subproductos de cosechas)?'.tr,
    '¿Se usan como suplementos de origen Animal para la alimentación como harinas, Pollinasa u otros?'.tr,
    '¿Se respetan los periodos de carecia de los insumos agrícolas y se tiene registro de ello?'.tr,
    '¿Se realizan rotación de potreros dando periodos de descanso adecuados para la recuperación de pasturas?'.tr,
    '¿El predio cuenta con suficiente Almacenamiento de agua para todas las épocas del año?'.tr,
    '¿El predio cuenta con un sistema de distribución de agua adecuado que permita acceso fácil y permanente a los animales en la finca?'.tr,
    '¿En épocas criticas se realiza suplementación con silo y/o heno  o material forrajero arbustivo a los animales?'.tr,
    '¿Las fuentes de agua para consumo animal están expuestas a químicos lixiviados u otro contaminante?'.tr,
    '¿Se suplementa a los animales con urea como fuente proteica?'.tr,
    '¿Se Utilizan promotores de crecimiento antibióticos o materias  de naturaleza químicas en la alimentación?'.tr,
    '¿Se cuenta con adecuado almacenamiento de insumos como sales mineralizadas, Heno u otros  sin riesgo de contaminantes químicos?'.tr,
    '¿El predio cuenta con buen cercado y adecuada delimitación del predio?'.tr,
    '¿Se verifica uso de arboles en los potreros, conservación y fomento de uso de sistemas silvopastoriles?'.tr,
    '¿Se observa protección de fuentes de agua?'.tr,
  ];
  static List<String> get assessmentQuestions2 => [
    '¿La empresa cuenta con asistencia técnica Veterinaria?'.tr,
    '¿La empresa cuenta con plan sanitario avalado por un Médico veterinario con tarjeta profesional vigente?'.tr,
    '¿Se Cuenta con almacenamiento adecuado de medicamentos e insumos de uso veterinario?'.tr,
    '¿Se evidencia movilizaciones según norma ICA cumpliendo con requisitos sanitarios GSMI?'.tr,
    '¿La finca cuenta con protocolo de manejo y reporte de enfermedades de control oficial?'.tr,
    '¿Se evidencian  insumos vencidos en los inventarios?'.tr,
    '¿Se Evidencia sustancias prohibidas por autoridad sanitaria en el predio?'.tr,
    '¿se respetan los tiempos de retiro de los medicamentos veterinarios y hay evidencia de ello?'.tr,
  ];
  static List<String> get assessmentQuestions3 => [
    '¿Los animales están individualmente identificados con numeración en la piel o chapeta con numero único claro y visible?'.tr,
    '¿Se cuenta con registros de inventarios de los animales que pastan en el predio (formato de pesajes o registros individuales de eventos)?'.tr,
    'Se evidencia registros de los eventos sanitarios individuales y/o grupales (Vacunaciones, Tratamientos con medicamentos, desparasitaciones, Baños u otros)?'.tr,
    '¿Se cuenta con registros de diagnósticos de enfermedades y de mortalidades?'.tr,
    '¿Se evidencia que La empresa tiene vacunación vigente contra Fiebre Aftosa?'.tr,
    '¿Se cuenta con registro de inventario básico de medicamentos de emergencias Veterinarias  con fecha vigente de vencimiento?'.tr,
  ];
  static List<String> get assessmentQuestions4 => [
    '¿Los animales están adaptados a las condiciones agroecológicas de la zona donde se encuentra del sistema de producción?'.tr,
    '¿Se verifica que los animales están en buenas condición corporal y sanitaria?'.tr,
    '¿Los animales tienen suficiente agua y alimento de manera permanente?'.tr,
    '¿Se observa un buen trato por parte de los responsables del manejo a los animales?'.tr,
    '¿Los animales muestran un comportamiento natural en pastoreo?'.tr,
    '¿Se cuentan con instalaciones como corrales embarcaderos, cercados bebederos en buen estado y que no permiten causar lesiones a los animales?'.tr,
    'Se utiliza Tábano eléctrico, palos, garrochas u otros elementos que causen lesión  o dolor durante el manejo a los animales?'.tr,
    '¿Se verifica una adecuada relación hombre animal con las personas encargadas del manejo?'.tr,
  ];
  static List<String> get assessmentQuestions5 => [
    '¿El personal Vinculado a la empresa ganadera cuenta con contrato laboral y prestaciones sociales según normatividad vigente?'.tr,
    '¿Se cuenta con plan de capacitación permanente para el personal encargado de los animales?'.tr,
    '¿El personal cuenta con condiciones adecuadas para realizar sus labores en su sitio de trabajo?'.tr,
    '¿El personal cuenta con dotación verificable al momento de la visita?'.tr,
  ];

  /// assessment step 6 upload images
  /// assessment step 7 final
}
