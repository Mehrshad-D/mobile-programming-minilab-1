import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/application.dart';
import '../models/auth_session.dart';
import '../models/resume.dart';
import '../models/user.dart';

/// Handles local persistence of user data and app state
class StorageService {
  static const String _keyCurrentUser = 'current_user';
  static const String _keyRegisteredUsers = 'registered_users';
  static const String _keyAppliedJobs = 'applied_jobs';
  static const String _keySession = 'auth_session';
  static const String _keyResumePrefix = 'resume_';

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
  // Auth session (Sanctum cookie jar) persistence — section 5.3
  // ---------------------------------------------------------------------------

  /// Persist the CSRF token + session cookies so the session survives restarts.
  static Future<void> saveSession(AuthSession session) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keySession, jsonEncode(session.toJson()));
  }

  /// Read the stored auth session, or `null` if none.
  static Future<AuthSession?> getSession() async {
    final prefs = await _getPrefs();
    final sessionJson = prefs.getString(_keySession);
    if (sessionJson == null) return null;
    return AuthSession.fromJson(
      jsonDecode(sessionJson) as Map<String, dynamic>,
    );
  }

  /// Clear the auth session (logout).
  static Future<void> clearSession() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keySession);
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

  // ---------------------------------------------------------------------------
  // Resume persistence (Section 5.4)
  // ---------------------------------------------------------------------------

  static String _resumeKey(String userId) => '$_keyResumePrefix$userId';

  /// Persist the user's resume so it survives app restarts.
  static Future<void> saveResume(String userId, Resume resume) async {
    final prefs = await _getPrefs();
    await prefs.setString(_resumeKey(userId), jsonEncode(resume.toJson()));
  }

  /// Load the persisted resume for a user, or `null` if none exists.
  static Future<Resume?> getResume(String userId) async {
    final prefs = await _getPrefs();
    final resumeJson = prefs.getString(_resumeKey(userId));
    if (resumeJson == null) return null;
    return Resume.fromJson(jsonDecode(resumeJson) as Map<String, dynamic>);
  }

  /// Remove the persisted resume (e.g. on account deletion).
  static Future<void> clearResume(String userId) async {
    final prefs = await _getPrefs();
    await prefs.remove(_resumeKey(userId));
  }

  // ---------------------------------------------------------------------------
  // Applications persistence (Section 5.5)
  // ---------------------------------------------------------------------------

  static String _applicationsKey(String userId) => 'applications_$userId';

  /// Persist the user's applications so they survive app restarts.
  static Future<void> saveApplications(
    String userId,
    List<JobApplication> applications,
  ) async {
    final prefs = await _getPrefs();
    final encoded = jsonEncode(applications.map((a) => a.toJson()).toList());
    await prefs.setString(_applicationsKey(userId), encoded);
  }

  /// Load the persisted applications for a user, or an empty list if none.
  static Future<List<JobApplication>> getApplications(String userId) async {
    final prefs = await _getPrefs();
    final json = prefs.getString(_applicationsKey(userId));
    if (json == null) return [];
    final List<dynamic> decoded = jsonDecode(json);
    return decoded
        .map((e) => JobApplication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Remove all persisted applications for a user.
  static Future<void> clearApplications(String userId) async {
    final prefs = await _getPrefs();
    await prefs.remove(_applicationsKey(userId));
  }
}