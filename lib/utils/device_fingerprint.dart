import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Generates a stable device fingerprint/visitor ID similar to FingerprintJS Pro
/// This ID persists across app sessions and can be used to identify users
class DeviceFingerprint {
  static const String _visitorIdKey = 'device_visitor_id';

  /// Gets or generates a visitor ID for this device
  /// Returns a stable ID that persists across app sessions
  static Future<String?> getVisitorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we already have a stored visitor ID
      final cachedId = prefs.getString(_visitorIdKey);
      if (cachedId != null && cachedId.isNotEmpty) {
        return cachedId;
      }

      // Generate a new visitor ID based on device characteristics
      final visitorId = await _generateVisitorId();
      
      // Store it for future use
      if (visitorId != null) {
        await prefs.setString(_visitorIdKey, visitorId);
      }
      
      return visitorId;
    } catch (e) {
      print('Error getting visitor ID: $e');
      return null;
    }
  }

  /// Generates a unique visitor ID based on device characteristics
  static Future<String?> _generateVisitorId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      Map<String, String> deviceData = {};
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceData = {
          'device': androidInfo.device,
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'manufacturer': androidInfo.manufacturer,
          'product': androidInfo.product,
          'hardware': androidInfo.hardware,
          'androidId': androidInfo.id,
          'osVersion': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt.toString(),
          'packageName': packageInfo.packageName,
          'appVersion': packageInfo.version,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceData = {
          'name': iosInfo.name,
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'identifierForVendor': iosInfo.identifierForVendor ?? '',
          'packageName': packageInfo.packageName,
          'appVersion': packageInfo.version,
        };
      } else if (kIsWeb) {
        // For web, use a combination of available info
        deviceData = {
          'packageName': packageInfo.packageName,
          'appVersion': packageInfo.version,
          'platform': 'web',
        };
      } else {
        // For other platforms, use basic info
        deviceData = {
          'packageName': packageInfo.packageName,
          'appVersion': packageInfo.version,
          'platform': Platform.operatingSystem,
        };
      }

      // Create a hash from the device data
      final dataString = deviceData.entries
          .map((e) => '${e.key}:${e.value}')
          .join('|');
      
      final bytes = utf8.encode(dataString);
      final digest = sha256.convert(bytes);
      
      return digest.toString();
    } catch (e) {
      print('Error generating visitor ID: $e');
      return null;
    }
  }

  /// Clears the stored visitor ID (useful for testing or reset)
  static Future<void> clearVisitorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_visitorIdKey);
    } catch (e) {
      print('Error clearing visitor ID: $e');
    }
  }
}

