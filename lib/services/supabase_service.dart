import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moto_rent_dumaguete/config/supabase_config.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  // Get the Supabase client
  SupabaseClient get client {
    if (_client == null) {
      throw Exception(
          'Supabase has not been initialized. Call initialize() first.');
    }
    return _client!;
  }

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: SupabaseConfig.enableDebugLogs,
    );
    _client = Supabase.instance.client;
  }

  // Auth helpers
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  String? get currentUserId => currentUser?.id;
  Session? get currentSession => client.auth.currentSession;

  // Sign up with email and password
  // Note: emailRedirectTo is set to null because email verification is handled by Resend service
  // This prevents Supabase from sending duplicate emails and avoids rate limiting
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: userData,
      emailRedirectTo: null,
    );
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.motorentdumaguete://reset-password',
    );
  }

  // Update user profile
  Future<UserResponse> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
        data: data,
      ),
    );
  }

  // Database operations

  // Get all records from a table
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final response = await client.from(table).select();
    return List<Map<String, dynamic>>.from(response);
  }

  // Get record by ID
  Future<Map<String, dynamic>?> getById(String table, String id) async {
    final response =
        await client.from(table).select().eq('id', id).maybeSingle();
    return response;
  }

  // Get records with filter
  Future<List<Map<String, dynamic>>> getWhere(
    String table,
    String column,
    dynamic value,
  ) async {
    final response = await client.from(table).select().eq(column, value);
    return List<Map<String, dynamic>>.from(response);
  }

  // Insert record
  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    final response = await client.from(table).insert(data).select().single();
    return response;
  }

  // Update record
  Future<Map<String, dynamic>> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    final response =
        await client.from(table).update(data).eq('id', id).select().single();
    return response;
  }

  // Delete record
  Future<void> delete(String table, String id) async {
    await client.from(table).delete().eq('id', id);
  }

  // Storage operations

  // Upload file to storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List fileBytes,
    String? contentType,
  }) async {
    await client.storage.from(bucket).uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    return client.storage.from(bucket).getPublicUrl(path);
  }

  // Get public URL for a file
  String getPublicUrl(String bucket, String path) {
    return client.storage.from(bucket).getPublicUrl(path);
  }

  // Delete file from storage
  Future<void> deleteFile(String bucket, String path) async {
    await client.storage.from(bucket).remove([path]);
  }

  // Realtime subscriptions

  // Subscribe to table changes
  RealtimeChannel subscribeToTable(
    String table,
    void Function(PostgresChangePayload payload) callback,
  ) {
    return client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: callback,
        )
        .subscribe();
  }

  // Unsubscribe from channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }
}
