import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const cloudName = 'dua4hldkk';
  static const uploadPreset = 'YOUR_UPLOAD_PRESET';

  static Future<String?> uploadImage(File imageFile) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ));

    final response = await request.send();

    if (response.statusCode == 200) {
      final res = await response.stream.bytesToString();
      return jsonDecode(res)['secure_url'];
    }
    return null;
  }
}
