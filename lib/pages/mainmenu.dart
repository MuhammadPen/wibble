// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fpjs_pro_plugin/error.dart';
import 'package:fpjs_pro_plugin/region.dart';
import 'package:fpjs_pro_plugin/fpjs_pro_plugin.dart';
import 'package:uuid/uuid.dart';
import 'package:wibble/components/user_form.dart';
import 'package:wibble/env/env.dart';
import 'package:wibble/firebase/firebase_utils.dart';

import 'package:wibble/main.dart';
import 'package:wibble/types.dart';

class Mainmenu extends StatefulWidget {
  const Mainmenu({super.key});

  @override
  State<Mainmenu> createState() => _MainmenuState();
}

class _MainmenuState extends State<Mainmenu> {
  bool _hasNavigated = false; // Add flag to prevent multiple navigations
  var identifiedUser;

  @override
  void initState() {
    super.initState();
    initFingerprint();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final store = Provider.of<Store>(context);
    final lobbyData = store.lobbyData;

    if (lobbyData.playerCount > 1 && !_hasNavigated) {
      _hasNavigated = true; // Set flag to prevent future navigations
      // Defer state changes until after the current build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        store.isMatchmaking = false;
        Navigator.pushNamed(context, "/${Routes.gameplay.name}");
      });
    }
  }

  void initFingerprint() async {
    await FpjsProPlugin.initFpjs(
      Env.FINGERPRINT_API_KEY, // insert your API key here
      region: Region.us, // Insert the data region of your Fingerprint workspace
    );
    identifyUser();
  }

  // Identify visitor
  void identifyUser() async {
    try {
      var visitorId = await FpjsProPlugin.getVisitorId();
      var visitorData = await FpjsProPlugin.getVisitorData();

      var user = await getUser(userId: visitorId ?? Uuid().v4());

      print(user);

      if (user != null) {
        identifiedUser = user;
      } else {
        UserFormDialog.show(
          context,
          onSubmit: (username) async {
            final user = User(
              id: visitorId ?? Uuid().v4(),
              username: username,
              rank: Rank.bronze,
              createdAt: DateTime.now(),
            );
            await createUser(user: user);

            identifiedUser = user;
          },
        );
      }
    } on FingerprintProError catch (e) {
      // Process the error
      print('Error identifying visitor: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<Store>(context);
    final isMatchmaking = store.isMatchmaking;

    if (identifiedUser != null) {
      store.user = identifiedUser;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      store.resumeMatch();
    });

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      textStyle: TextStyle(fontSize: 16),
      elevation: 0,
    );

    return Scaffold(
      appBar: null,
      body: Center(
        child: isMatchmaking
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Finding opponent...', style: TextStyle(fontSize: 18)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Welcome message
                  if (store.user.username.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Text(
                        'Welcome ${store.user.username}!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: Icon(Icons.person),
                    label: Text("1v1"),
                    onPressed: () async {
                      await store.startMatchmaking();
                    },
                    style: buttonStyle,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: Icon(Icons.person),
                    label: Text("Private lobby"),
                    onPressed: () {},
                    style: buttonStyle,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: Icon(Icons.help),
                    label: Text("How to play"),
                    onPressed: () {},
                    style: buttonStyle,
                  ),
                  SizedBox(height: 10),
                  if (!kIsWeb)
                    ElevatedButton.icon(
                      icon: Icon(Icons.exit_to_app),
                      label: Text("Exit"),
                      onPressed: () {
                        exit(0);
                      },
                      style: buttonStyle,
                    ),
                ],
              ),
      ),
    );
  }
}
