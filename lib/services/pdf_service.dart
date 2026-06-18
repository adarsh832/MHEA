import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class PdfApiService {
  // Replace with your VPS IP or localhost (10.0.2.2 for Android Emulator)
  final String baseUrl = "https://adarsh1924-test.hf.space/api/v1";
// http://192.168.29.145:8000/api/v1
  //https://adarsh1924-test.hf.space/api/v1
  Future<Uint8List?> generatePdf(Map<String, String> formData, Map<String, File> files, {String? templateName}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/${templateName == "form-2.html" ? "generate-secondary-pdf" : "generate-pdf"}'));

      // 1. Add Text Fields
      request.fields.addAll(formData);

      // 2. Add Image Files
      // Keys must match: idPhoto1, idPhoto2
      for (var entry in files.entries) {
        request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value.path));
      }

      print("Sending request to backend...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print("Success! PDF bytes received.");
        return response.bodyBytes;
      } else {
        print("Error: ${response.statusCode}");
        print("Body: ${response.body}");
        throw Exception("Failed to generate PDF: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
      rethrow;
    }
  }
}
