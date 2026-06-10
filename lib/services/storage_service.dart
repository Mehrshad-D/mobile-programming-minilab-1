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
  // Registered users (for validation)
  // ---------------------------------------------------------------------------

  /// Save all registered users
  static Future<void> saveRegisteredUsers(Map<String, User> users) async {
    final prefs = await _getPrefs();
    final usersMap = <String, dynamic>{};
    for (final entry in users.entries) {
      usersMap[entry.key] = entry.value.toJson();
    }
    await prefs.setString(_keyRegisteredUsers, jsonEncode(usersMap));
  }

  /// Get all registered users
  static Future<Map<String, User>> getRegisteredUsers() async {
    final prefs = await _getPrefs();
    final usersJson = prefs.getString(_keyRegisteredUsers);
    if (usersJson == null) return {};
    
    final Map<String, dynamic> decoded = jsonDecode(usersJson);
    final Map<String, User> result = {};
    for (final entry in decoded.entries) {
      result[entry.key] = User.fromJson(entry.value as Map<String, dynamic>);
    }
    return result;
  }

  /// Register a new user
  static Future<bool> registerUser(String email, User user) async {
    final users = await getRegisteredUsers();
    if (users.containsKey(email)) {
      return false; // User already exists
    }
    users[email] = user;
    await saveRegisteredUsers(users);
    return true;
  }

  /// Validate login credentials
  static Future<User?> validateLogin(String email, String password) async {
    final users = await getRegisteredUsers();
    final user = users[email];
    // In a real app, you'd hash passwords. For mock, check password == email
    if (user != null && password == '123456') {
      return user;
    }
    return null;
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