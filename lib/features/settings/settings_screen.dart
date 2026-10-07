import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFFFFF1F4), borderRadius: BorderRadius.circular(28)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💕', style: TextStyle(fontSize: 34)),
            const SizedBox(height: 8),
            Text('Love Vault', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text('Shared settings for your private space. Question Bank now has its own shortcut in the menu.'),
          ]),
        ),
      ],
    ),
  );
}
