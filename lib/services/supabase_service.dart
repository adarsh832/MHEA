import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class SupabaseService {
  final _supabase = Supabase.instance.client;

  /// Uploads a PDF to Supabase Storage and returns the public URL.
  Future<String> uploadPdf({
    required Uint8List pdfBytes,
    required String pskNumber,
    required String formType,
  }) async {
    final fileName =
        "${formType}_${pskNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final path = "forms/$pskNumber/$fileName";

    try {
      // Upload the file
      await _supabase.storage
          .from('organization_docs')
          .uploadBinary(
            path,
            pdfBytes,
            fileOptions: const FileOptions(contentType: 'application/pdf'),
          );

      // Get Public URL
      final String publicUrl = _supabase.storage
          .from('organization_docs')
          .getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print("Supabase Upload Error: $e");
      rethrow;
    }
  }

  /// Saves form metadata and PDF URL to the user_forms table.
  Future<void> saveFormRecord({
    required String userName,
    required String pskNumber,
    required String formType,
    required String pdfUrl,
  }) async {
    try {
      await _supabase.from('user_forms').insert({
        'user_name': userName,
        'psk_number': pskNumber,
        'form_type': formType,
        'pdf_url': pdfUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Supabase DB Error: $e");
      rethrow;
    }
  }
}
