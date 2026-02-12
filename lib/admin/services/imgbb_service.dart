// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'dart:typed_data';

// class ImgBBService {
//   // TODO: Replace with your actual ImgBB API key
//   static const String _apiKey = '68e26852a118024836b40396956cd3e5';
//   static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

//   /// Upload image to ImgBB
//   /// Returns the image URL if successful, null if failed
//   Future<String?> uploadImage(Uint8List imageBytes, String fileName) async {
//     try {
//       print('📤 Uploading image to ImgBB: $fileName');

//       // Convert image bytes to base64
//       String base64Image = base64Encode(imageBytes);

//       // Create multipart request
//       var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

//       // Add API key and image
//       request.fields['key'] = _apiKey;
//       request.fields['image'] = base64Image;
//       request.fields['name'] = fileName;

//       // Send request
//       var streamedResponse = await request.send();
//       var response = await http.Response.fromStream(streamedResponse);

//       print('📥 Response status: ${response.statusCode}');

//       if (response.statusCode == 200) {
//         final jsonResponse = json.decode(response.body);

//         if (jsonResponse['success'] == true) {
//           final imageUrl = jsonResponse['data']['url'] as String;
//           print('✅ Image uploaded successfully: $imageUrl');
//           return imageUrl;
//         } else {
//           print('❌ Upload failed: ${jsonResponse['error']['message']}');
//           return null;
//         }
//       } else {
//         print('❌ HTTP Error: ${response.statusCode}');
//         print('Response: ${response.body}');
//         return null;
//       }
//     } catch (e) {
//       print('❌ Error uploading image: $e');
//       return null;
//     }
//   }

//   /// Validate if URL is a valid image URL
//   bool isValidImageUrl(String url) {
//     if (url.isEmpty) return false;

//     try {
//       final uri = Uri.parse(url);
//       if (!uri.hasScheme) return false;

//       // Check if it's a valid image extension
//       final validExtensions = [
//         '.jpg',
//         '.jpeg',
//         '.png',
//         '.gif',
//         '.webp',
//         '.bmp'
//       ];
//       final lowerUrl = url.toLowerCase();

//       return validExtensions.any((ext) => lowerUrl.contains(ext)) ||
//           lowerUrl.contains('imgbb.com') ||
//           lowerUrl.contains('imgur.com') ||
//           lowerUrl.contains('cloudinary.com');
//     } catch (e) {
//       return false;
//     }
//   }
// }
