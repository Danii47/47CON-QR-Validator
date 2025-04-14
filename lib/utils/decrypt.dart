import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_dotenv/flutter_dotenv.dart';

String decrypt(String encryptedBase64) {
  final secretKey = dotenv.env['SECRET_KEY']!;
  final key = encrypt.Key.fromUtf8(secretKey);

  try {
    final data = base64.decode(encryptedBase64.trim());
    final iv = encrypt.IV(Uint8List.fromList(data.sublist(0, 16)));
    final encryptedData = data.sublist(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final decrypted = encrypter.decrypt(encrypt.Encrypted(Uint8List.fromList(encryptedData)), iv: iv);

    return decrypted;
  } catch (e) {
    return "-";
  }
}