import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'receipts';

  /// Upload receipt image to Supabase Storage
  /// Returns the public URL of the uploaded file
  Future<String> uploadReceipt(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = '$userId/$timestamp.$extension';

      // Upload to Supabase Storage
      await _supabase.storage
          .from(_bucketName)
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload receipt: $e');
    }
  }

  /// Delete receipt from storage
  Future<void> deleteReceipt(String fileUrl) async {
    try {
      // Extract filename from URL
      final uri = Uri.parse(fileUrl);
      final fileName = uri.pathSegments.last;

      await _supabase.storage.from(_bucketName).remove([fileName]);
    } catch (e) {
      throw Exception('Failed to delete receipt: $e');
    }
  }
}
