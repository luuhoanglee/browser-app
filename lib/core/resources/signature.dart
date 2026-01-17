class AppSignature {
  static final Map<String, dynamic> login = {
    "id": "123",
    "type": "certification",
    "timestamp": DateTime.now().toIso8601String(),
  };
  static final Map<String, dynamic> eventCreateGrassFedCertificate = {
    "id": "1",
    "type": "grassfed_certificate",
    "timestamp": DateTime.now().toIso8601String(),
  };
}
