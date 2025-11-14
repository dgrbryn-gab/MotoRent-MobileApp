import 'package:flutter/foundation.dart';

class SupabaseConfig {
  // Supabase project credentials
  // Project: hceylmoutuzldbywawtm
  // https://app.supabase.com/project/hceylmoutuzldbywawtm/settings/api

  static const String supabaseUrl = 'https://hceylmoutuzldbywawtm.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjZXlsbW91dHV6bGRieXdhd3RtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5NTEwNzQsImV4cCI6MjA3NjUyNzA3NH0.z5gAl_zSesZ_jgk6-JEz1S_fHtakPL9yqw_xubtJqgU';

  // Optional: Add custom configurations
  static const bool enableDebugLogs = kDebugMode;

  // API endpoints (relative to your Supabase URL)
  static const String authEndpoint = '/auth/v1';
  static const String restEndpoint = '/rest/v1';
  static const String storageEndpoint = '/storage/v1';

  // Table names (matching your web application database)
  static const String usersTable = 'users';
  static const String motorcyclesTable = 'motorcycles';
  static const String reservationsTable = 'reservations';

  // Alias for backward compatibility with booking references
  static const String bookingsTable = reservationsTable;
  static const String paymentsTable = 'payments';
  static const String notificationsTable = 'notifications';
  static const String documentVerificationsTable = 'document_verifications';

  // Storage buckets
  static const String motorcycleImagesBucket = 'motorcycle-images';
  static const String documentsBucket =
      'documents'; // Changed to match actual bucket
  static const String userDocumentsBucket = 'documents'; // Alias
  static const String profilePicturesBucket = 'profile-pictures';
}
