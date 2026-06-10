import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/job.dart';

/// Handles local persistence of user data and app state
class StorageService {
  static const String _keyCurrentUser = 'current_user';
  static const String _keyRegisteredUsers = 'registered_users';
  static const String _keyAppliedJobs = 'applied_jobs';

  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // ---------------------------------------------------------------------------
  // User persistence
  // ---------------------------------------------------------------------------

  /// Save current logged-in user
  static Future<void> saveCurrentUser(User user) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyCurrentUser, jsonEncode(user.toJson()));
  }

  /// Get current logged-in user
  static Future<User?> getCurrentUser() async {
    final prefs = await _getPrefs();
    final userJson = prefs.getString(_keyCurrentUser);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
  }

  /// Clear current user (logout)
  static Future<void> clearCurrentUser() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyCurrentUser);
  }

  // ---------------------------------------------------------------------------
  // Registered users (for validation) - NOW WITH PASSWORD STORAGE
  // ---------------------------------------------------------------------------

  /// Structure to store user with password
  static const String _keyUserPassword = '_password';
  
  /// Save all registered users with passwords
  static Future<void> saveRegisteredUsers(Map<String, Map<String, dynamic>> usersWithPasswords) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyRegisteredUsers, jsonEncode(usersWithPasswords));
  }

  /// Get all registered users with their passwords
  static Future<Map<String, Map<String, dynamic>>> getRegisteredUsersWithPasswords() async {
    final prefs = await _getPrefs();
    final usersJson = prefs.getString(_keyRegisteredUsers);
    if (usersJson == null) return {};
    
    return (jsonDecode(usersJson) as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as Map<String, dynamic>)
    );
  }

  /// Register a new user with their password
  static Future<bool> registerUser(String email, User user, String password) async {
    final users = await getRegisteredUsersWithPasswords();
    if (users.containsKey(email)) {
      return false; // User already exists
    }
    
    users[email] = {
      'user': user.toJson(),
      'password': password, // Store the actual password
    };
    
    await saveRegisteredUsers(users);
    return true;
  }

  /// Validate login credentials with actual password
  static Future<User?> validateLogin(String email, String password) async {
    final users = await getRegisteredUsersWithPasswords();
    final userData = users[email];
    
    if (userData != null && userData['password'] == password) {
      return User.fromJson(userData['user'] as Map<String, dynamic>);
    }
    return null;
  }

  /// Update user in registered users list (keep password unchanged)
  static Future<void> updateRegisteredUser(User user) async {
    final users = await getRegisteredUsersWithPasswords();
    if (users.containsKey(user.email)) {
      final existingPassword = users[user.email]!['password'];
      users[user.email] = {
        'user': user.toJson(),
        'password': existingPassword,
      };
      await saveRegisteredUsers(users);
    }
  }

  // ---------------------------------------------------------------------------
  // Applied jobs persistence
  // ---------------------------------------------------------------------------

  /// Save applied jobs for current user
  static Future<void> saveAppliedJobs(String userId, List<String> jobIds) async {
    final prefs = await _getPrefs();
    await prefs.setString('applied_jobs_$userId', jsonEncode(jobIds));
  }

  /// Get applied jobs for current user
  static Future<List<String>> getAppliedJobs(String userId) async {
    final prefs = await _getPrefs();
    final jobsJson = prefs.getString('applied_jobs_$userId');
    if (jobsJson == null) return [];
    final List<dynamic> decoded = jsonDecode(jobsJson);
    return decoded.map((e) => e.toString()).toList();
  }

  /// Add an applied job
  static Future<void> addAppliedJob(String userId, String jobId) async {
    final jobs = await getAppliedJobs(userId);
    if (!jobs.contains(jobId)) {
      jobs.add(jobId);
      await saveAppliedJobs(userId, jobs);
    }
  }
}