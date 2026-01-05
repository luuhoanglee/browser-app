import 'package:string_validator/string_validator.dart' show isEmail;

class ValidateData {
  static validateEmail({ required String email }) {
    return isEmail(email);
  }
  static validatePhoneColombia({ required String phoneNumber }) {
    return RegExp(r'^(?:\+57|57)?\s*3\d{2}\s*\d{3}\s*\d{4}$').hasMatch(phoneNumber);
  }
  static bool isImageFile(String? path) {
    if (path == null) return false;
    final ext = path.split('.').last.toLowerCase();
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic'];
    return imageExtensions.contains(ext);
  }
  static bool isVideoFile(String? path) {
    if (path == null) return false;
    final ext = path.split('.').last.toLowerCase();
    const videoExtensions = [
      'mp4', 'mov', 'avi', 'mkv', 'flv', 'wmv', 'webm', '3gp', 'm4v'
    ];
    return videoExtensions.contains(ext);
  }
}