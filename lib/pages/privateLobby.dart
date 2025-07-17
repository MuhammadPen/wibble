import 'package:flutter/material.dart';

class PrivateLobby extends StatefulWidget {
  const PrivateLobby({super.key});

  @override
  State<PrivateLobby> createState() => _PrivateLobbyState();
}

class _PrivateLobbyState extends State<PrivateLobby> {
  void _printHello() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Private Lobby')),
      body: Center(
        child: ElevatedButton(
          onPressed: _printHello,
          child: const Text('Print Hello'),
        ),
      ),
    );
  }
}
