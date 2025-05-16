import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://rvbktixsfavqrprvluah.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ2Ymt0aXhzZmF2cXJwcnZsdWFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY3MTg3NzgsImV4cCI6MjA2MjI5NDc3OH0.RMtPFUzILf5DzKXSorOwJWHTVFixz-CX567ivg7y5Qw',
    );
  }

  static Future<AuthResponse> signUp(
      String email,
      String password,
      {Map<String, dynamic>? metadata}
      ) async {
    // Make sure displayName is saved in the right format Supabase expects
    final userMetadata = metadata ?? {};

    // Ensure we're using the correct metadata field names
    // Supabase specifically looks for 'name' for the display name in the dashboard
    if (userMetadata.containsKey('display_name')) {
      userMetadata['name'] = userMetadata['display_name'];
    }

    return await client.auth.signUp(
      email: email,
      password: password,
      data: userMetadata,
    );
  }

  // Updated method to update user profile in the profiles table
  static Future<void> updateUserProfile(Map<String, dynamic> profileData, {File? profileImage}) async {
    // Check if user is authenticated
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // First, update auth metadata for backward compatibility
    await client.auth.updateUser(
      UserAttributes(
        data: profileData,
      ),
    );

    // Upload profile image if provided
    String? profileImageUrl;
    if (profileImage != null) {
      profileImageUrl = await uploadProfileImage(profileImage, user.id);
      profileData['profile_image_url'] = profileImageUrl;
    }

    // Check if profile exists
    final response = await client
        .from('profiles')
        .select()
        .eq('user_id', user.id)
        .single();

    if (response != null) {
      // Update existing profile
      await client
          .from('profiles')
          .update(profileData)
          .eq('user_id', user.id);
    } else {
      // Create new profile
      profileData['user_id'] = user.id;
      await client
          .from('profiles')
          .insert(profileData);
    }
  }

  // Method to upload profile image
  static Future<String> uploadProfileImage(File image, String userId) async {
    final fileExt = path.extension(image.path);
    final fileName = '${userId}_${const Uuid().v4()}$fileExt';
    final filePath = 'profile-images/$fileName';

    // Upload to Supabase Storage
    await client.storage
        .from('profile-images')
        .upload(filePath, image);

    // Get the public URL
    final imageUrl = client.storage
        .from('profile-images')
        .getPublicUrl(filePath);

    return imageUrl;
  }

  // Method to get profile data
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}