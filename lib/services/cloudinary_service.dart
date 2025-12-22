import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const _cloudName = 'dhrtj8kqn';
  static const _uploadPreset = 'esheba';

  static Future<String?> uploadImage(File file) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode != 200) return null;

    final resStr = await response.stream.bytesToString();
    final data = jsonDecode(resStr);
    return data['secure_url'];
  }
}
