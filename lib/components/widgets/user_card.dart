import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wibble/components/ui/button.dart';
import 'package:wibble/components/widgets/user_form.dart';
import 'package:wibble/firebase/firebase_utils.dart';
import 'package:wibble/types.dart';
import 'package:wibble/main.dart';

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback? onCopy;

  const UserCard({Key? key, required this.user, this.onCopy}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 332),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          CustomButton(
            onPressed: () => _handleEdit(context),
            height: 60,
            width: 70,
            backgroundColor: Color(0xffF2EEDB),
            borderColor: Colors.transparent,
            shadowColor: Color.fromARGB(91, 242, 238, 219),
            loadingColor: Colors.black,
            child: Icon(Icons.edit),
          ),
          Flexible(
            child: CustomButton(
              onPressed: () => _handleCopy(context),
              height: 60,
              backgroundColor: Color(0xffF2EEDB),
              borderColor: Colors.transparent,
              shadowColor: Color.fromARGB(91, 242, 238, 219),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(left: 30, right: 1),
                      child: Text(
                        user.username.length > 10
                            ? "${user.username.substring(0, 10)}..."
                            : user.username,
                        style: TextStyle(fontSize: 32, fontFamily: "Baloo"),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.copy),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCopy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: user.id));
    onCopy?.call();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ID copied: ${user.id.substring(0, 8)}...'),
        ),
      );
    }
  }

  Future<void> _handleEdit(BuildContext context) async {
    // if (isloa)
    final username = await UserFormDialog.show(context, dismissible: true);
    if (username == null) return;

    final updatedUser = User(
      id: user.id,
      username: username,
      rank: user.rank,
      createdAt: user.createdAt,
    );

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      UserCacheKeys.user.name,
      jsonEncode(updatedUser.toJson()),
    );
    context.read<Store>().user = updatedUser;

    try {
      //update username in firestore
      await updateUser(user: updatedUser);
    } catch (e) {
      print(e);
    }
  }
}


// GestureDetector(
//       onTap: () => _handleCopy(context),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(user.username),
//           const SizedBox(width: 8),
//           const Icon(Icons.copy),
//         ],
//       ),
//     );