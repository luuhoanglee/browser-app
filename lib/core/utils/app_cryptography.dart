import 'dart:convert';
import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:browser_app/core/logger/logger.dart';
import 'package:browser_app/core/services/encrypt_key/model/encrypt_key_model.dart';

class AppCryptography {

  /// Creates a new keypair using the Ed25519 algorithm.
  ///
  /// Return a map containing the public and private keys.
  /// ```json
  /// {
  ///   'publicKey': publicKey.bytes,
  ///   'privateKey': privateKey,
  /// }
  /// ```
  static Future<Map<String, dynamic>> createKeypair() async {
    final algorithm = Ed25519();

    // Generate a new keypair
    final keyPair = await algorithm.newKeyPair();

    // Extract public key
    final publicKey = await keyPair.extractPublicKey();

    // Extract private key in raw format
    final privateKey = await keyPair.extractPrivateKeyBytes();

    Logger.show('publicKey: ${base64Encode(publicKey.bytes)}');
    Logger.show('privateKey (raw): $privateKey');

    return {
      'publicKey': base64Encode(publicKey.bytes),
      'privateKey': privateKey,
    };
  }

  static String generateRandomPassword(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()_+-=';
    final rand = Random.secure();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<List<int>> decryptPrivateKey(String encrypted, String nonce, SecretKey p2) async {
    final aes = AesGcm.with256bits();
    final secretBox = SecretBox(
      base64Decode(encrypted),
      nonce: base64Decode(nonce),
      mac: Mac.empty,
    );
    return await aes.decrypt(secretBox, secretKey: p2);
  }

  static Future<EncryptKeyModel> encryptPrivateKey(List<int> privateKeyBytes) async {
    // Generate a random password
    final String password = generateRandomPassword(32);

    final aesGcm = AesGcm.with256bits();

    final salt = aesGcm.newNonce(); // random salt
    final secretKey = await deriveKeyFromPassword(password, salt);

    final nonce = aesGcm.newNonce();

    // Encrypt the private key
    final encrypted = await aesGcm.encrypt(
      privateKeyBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    EncryptKeyModel result = EncryptKeyModel(
      password: password,
      privateKey: base64Encode(encrypted.cipherText),
      nonce: base64Encode(encrypted.nonce),
      salt: base64Encode(salt),
      mac: base64Encode(encrypted.mac.bytes),
    );

    return result;
  }

  static Future<SecretKey>  deriveKeyFromPassword(String password, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    return await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  static Future<String> checksumChunk(Uint8List chunkData) async {
    final algorithm = Sha256();
    final hash = await algorithm.hash(chunkData);
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}