import 'package:flutter/material.dart';

import 'features/home/home_shell.dart';

class LoveVaultApp extends StatelessWidget {
  const LoveVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Love Vault',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8E3A59)),
      ),
      home: const HomeShell(),
    );
  }
}
