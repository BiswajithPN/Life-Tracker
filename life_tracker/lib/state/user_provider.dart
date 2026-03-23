import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'shared_prefs_provider.dart';

final userProvider = NotifierProvider<UserNotifier, UserModel?>(() {
  return UserNotifier();
});

class UserNotifier extends Notifier<UserModel?> {
  static const _usersKey = 'registered_users';
  static const _loggedInUserKey = 'logged_in_user';
  
  List<UserModel> _registeredUsers = [];

  @override
  UserModel? build() {
    final prefs = ref.watch(sharedPrefsProvider);
    
    // Load registered users
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(usersJson);
        _registeredUsers = decoded.map((e) => UserModel.fromJson(e)).toList();
      } catch (_) {}
    }

    // Load currently logged in user
    final currentUserJson = prefs.getString(_loggedInUserKey);
    if (currentUserJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(currentUserJson));
      } catch (_) {}
    }

    return null; // No user logged in initially
  }

  void _saveUsers() {
    final prefs = ref.read(sharedPrefsProvider);
    prefs.setString(_usersKey, jsonEncode(_registeredUsers.map((e) => e.toJson()).toList()));
  }

  void _saveState(UserModel? user) {
    state = user;
    final prefs = ref.read(sharedPrefsProvider);
    if (user == null) {
      prefs.remove(_loggedInUserKey);
    } else {
      prefs.setString(_loggedInUserKey, jsonEncode(user.toJson()));
    }
  }

  /// Register a new user. Returns error string or null on success.
  String? register(String username, String email, String password) {
    if (username.trim().isEmpty) return 'Username is required';
    if (email.trim().isEmpty) return 'Email is required';
    if (password.trim().isEmpty) return 'Password is required';
    if (password.length < 4) return 'Password must be at least 4 characters';

    // Check if username already taken
    final usernameExists = _registeredUsers.any(
      (u) => u.username.toLowerCase() == username.trim().toLowerCase(),
    );
    if (usernameExists) return 'Username is already taken. Try another name.';

    // Check if email already taken
    final emailExists = _registeredUsers.any(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
    );
    if (emailExists) return 'This email is already registered. Try logging in.';

    final user = UserModel(
      username: username.trim(),
      email: email.trim(),
      password: password,
    );
    _registeredUsers.add(user);
    _saveUsers();
    _saveState(user); // Auto-login after registration
    return null;
  }

  /// Login with username and password. Returns error string or null on success.
  String? login(String username, String password) {
    if (username.trim().isEmpty) return 'Username is required';
    if (password.trim().isEmpty) return 'Password is required';

    final usernameLower = username.trim().toLowerCase();
    
    // Check if user exists first
    final userExists = _registeredUsers.any((u) => u.username.toLowerCase() == usernameLower);
    if (!userExists) {
      return 'Account not found. Please create an account first.';
    }

    final users = _registeredUsers.where(
      (u) => u.username.toLowerCase() == usernameLower && u.password == password,
    );

    if (users.isEmpty) {
      return 'Incorrect password. Please try again.';
    }

    _saveState(users.first);
    return null;
  }

  void logout() {
    _saveState(null);
  }
}
