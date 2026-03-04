import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<void> storeData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (var entry in data.entries) {
        if (entry.value is String) {
          await prefs.setString(entry.key, entry.value);
        } else if (entry.value is int) {
          await prefs.setInt(entry.key, entry.value);
        } else if (entry.value is bool) {
          await prefs.setBool(entry.key, entry.value);
        } else if (entry.value is double) {
          await prefs.setDouble(entry.key, entry.value);
        } else if (entry.value is List) {
          final stringList = entry.value.map((e) => e.toString()).toList();
          await prefs.setStringList(entry.key, stringList);
        } else if (entry.value != null) {
          await prefs.setString(entry.key, jsonEncode(entry.value));
        }
      }
    } catch (e) {
    }
  }

  static Future<dynamic> getData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(key)) {
        final value = prefs.get(key);
        if (value is String) {
          return prefs.getString(key);
        } else if (value is int) {
          return prefs.getInt(key);
        } else if (value is double) {
          return prefs.getDouble(key);
        } else if (value is bool) {
          return prefs.getBool(key);
        } else if (value is List<String>) {
          return prefs.getStringList(key);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<String>> getUserRoles() async {
    try {
      final rolesJson = await getData('roles_json');

      if (rolesJson is String) {
        final List<dynamic> rolesList = jsonDecode(rolesJson);
        return List<String>.from(rolesList);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> storeUserRoles(dynamic roles) async {
    try {
      List<String> rolesList = [];
      
      if (roles is List) {
        // Roles is a List (e.g., ["admin", "manager"])
        rolesList = List<String>.from(roles.map((r) => r.toString().toLowerCase()));
      } else if (roles is Map) {
        // Roles is a Map (e.g., {"ADMIN": "admin"}) - extract keys
        rolesList = roles.keys.map((k) => k.toString().toLowerCase()).toList();
      }
      
      debugPrint('🔐 Storing user roles: $rolesList');
      final rolesJson = jsonEncode(rolesList);
      await storeData({'roles_json': rolesJson});
    } catch (e) {
      debugPrint('🔐 Error storing user roles: $e');
    }
  }

  static Future<bool> hasRole(String role) async {
    final roles = await getUserRoles();
    return roles.contains(role);
  }

  static Future<void> removeData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(key)) {
        await prefs.remove(key);
      }
    } catch (e) {
    }
  }

  static Future<void> clearData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
    }
  }

  static Future<void> setThemeMode(String mode) async {
    await storeData({'theme_mode': mode});
  }

  static Future<String?> getThemeMode() async {
    return await getData('theme_mode');
  }
}
