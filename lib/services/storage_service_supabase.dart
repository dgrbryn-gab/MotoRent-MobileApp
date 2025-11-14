import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageServiceSupabase {
  static final StorageServiceSupabase _instance =
      StorageServiceSupabase._internal();
  factory StorageServiceSupabase() => _instance;
  StorageServiceSupabase._internal();

  final _supabase = Supabase.instance.client;

  /// Upload a file to Supabase Storage and return the public URL
  Future<String?> uploadDocument({
    required String filePath,
    required String userId,
    required String fileName,
    String bucketName = 'documents',
  }) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        print('ERROR: File does not exist at path: $filePath');
        return null;
      }

      // Create a unique path: userId/fileName_timestamp.extension
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last;
      final uniqueFileName =
          '${fileName.split('.').first}_$timestamp.$extension';
      final storagePath = '$userId/$uniqueFileName';

      print('DEBUG: Uploading file to Supabase Storage...');
      print('DEBUG: Bucket: $bucketName');
      print('DEBUG: Path: $storagePath');
      print('DEBUG: Local file: $filePath');

      // Upload the file
      await _supabase.storage.from(bucketName).upload(
            storagePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get the public URL
      final publicUrl =
          _supabase.storage.from(bucketName).getPublicUrl(storagePath);

      print('DEBUG: Upload successful!');
      print('DEBUG: Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('ERROR: Failed to upload file to Supabase Storage: $e');
      return null;
    }
  }

  /// Upload a license image
  Future<String?> uploadLicense({
    required String filePath,
    required String userId,
  }) async {
    final fileName = 'license_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await uploadDocument(
      filePath: filePath,
      userId: userId,
      fileName: fileName,
      bucketName: 'documents',
    );
  }

  /// Upload a profile picture
  Future<String?> uploadProfilePicture({
    required String filePath,
    required String userId,
  }) async {
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await uploadDocument(
      filePath: filePath,
      userId: userId,
      fileName: fileName,
      bucketName: 'documents',
    );
  }

  /// Upload a motorcycle image (for admin)
  Future<String?> uploadMotorcycleImage({
    required String filePath,
    required String motorcycleId,
  }) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        print('ERROR: File does not exist at path: $filePath');
        return null;
      }

      // Create a unique filename: motorcycleId_timestamp.jpg
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = filePath.split('.').last;
      final fileName = '${motorcycleId}_$timestamp.$extension';

      print('DEBUG: Uploading motorcycle image to Supabase Storage...');
      print('DEBUG: Bucket: motorcycle-images');
      print('DEBUG: Filename: $fileName');

      // Upload the file
      await _supabase.storage.from('motorcycle-images').upload(
            fileName,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get the public URL
      final publicUrl =
          _supabase.storage.from('motorcycle-images').getPublicUrl(fileName);

      print('DEBUG: Motorcycle image upload successful!');
      print('DEBUG: Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('ERROR: Failed to upload motorcycle image: $e');
      return null;
    }
  }

  /// Delete a file from Supabase Storage
  Future<bool> deleteFile({
    required String storagePath,
    String bucketName = 'documents',
  }) async {
    try {
      await _supabase.storage.from(bucketName).remove([storagePath]);
      print('DEBUG: Deleted file: $storagePath');
      return true;
    } catch (e) {
      print('ERROR: Failed to delete file: $e');
      return false;
    }
  }
}
