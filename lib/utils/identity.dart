import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:wibble/components/widgets/user_form.dart';
import 'package:wibble/firebase/firebase_utils.dart';
import 'package:wibble/types.dart';
import 'package:wibble/utils/device_fingerprint.dart';

Future<User?> identifyUser({required BuildContext context}) async {
  final prefs = await SharedPreferences.getInstance();
  var cachedUser = prefs.getString(UserCacheKeys.user.name);
  User? user;

  if (cachedUser != null) {
    try {
      return User.fromJson(jsonDecode(cachedUser));
    } catch (e) {
      print("🐾 error: $e");
    }
  }

  try {
    var visitorId = await DeviceFingerprint.getVisitorId();

    user = await getUser(userId: visitorId ?? Uuid().v4());

    if (user != null) {
      //cache user
      await prefs.setString(UserCacheKeys.user.name, jsonEncode(user.toJson()));
    } else {
      final username = await UserFormDialog.show(context, dismissible: false);

      user = User(
        id: visitorId ?? Uuid().v4(),
        username: username!,
        rank: Rank.bronze,
        createdAt: DateTime.now(),
      );

      await createUser(user: user);

      //cache user
      await prefs.setString(UserCacheKeys.user.name, jsonEncode(user.toJson()));
    }
  } catch (e) {
    // Process the error
    print('Error identifying visitor: $e');
  }
  return user;
}
