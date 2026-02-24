import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ImgBBService {
  static const String _apiKey = '68e26852a118024836b40396956cd3e5';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  Future<String?> uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      print('📤 Uploading image to ImgBB: $fileName');
      final base64Image = base64Encode(imageBytes);
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['key'] = _apiKey;
      request.fields['image'] = base64Image;
      request.fields['name'] = fileName;
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('📥 Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'] as Map<String, dynamic>;
          final candidates = <String?>[
            _nestedUrl(data, 'image'),
            _nestedUrl(data, 'medium'),
            data['display_url'] as String?,
            data['url'] as String?,
            _nestedUrl(data, 'thumb'),
          ];
          final url = candidates.firstWhere(
            (u) => u != null && u.isNotEmpty,
            orElse: () => null,
          );
          if (url != null) {
            print('✅ Image uploaded successfully: $url');
            return url;
          }
          print(
              '❌ Upload succeeded but no URL in response. Keys: ${data.keys}');
          return null;
        } else {
          print(
              '❌ ImgBB error: ${(jsonResponse['error'] as Map?)?['message']}');
          return null;
        }
      } else {
        print('❌ HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  String? _nestedUrl(Map<String, dynamic> data, String key) {
    try {
      final sub = data[key];
      return sub is Map ? sub['url'] as String? : null;
    } catch (_) {
      return null;
    }
  }

  bool isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme) return false;
      const exts = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
      final lower = url.toLowerCase();
      return exts.any((e) => lower.contains(e)) ||
          lower.contains('ibb.co') ||
          lower.contains('imgur.com') ||
          lower.contains('cloudinary.com') ||
          lower.contains('firebasestorage.googleapis.com');
    } catch (_) {
      return false;
    }
  }
}
