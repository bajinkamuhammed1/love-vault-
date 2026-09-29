import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/home/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'services/room_service.dart';

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
      home: const _AppGate(),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  late final RoomService _rooms;
  late Future<Map<String, dynamic>?> _roomFuture;

  @override
  void initState() {
    super.initState();
    _rooms = RoomService(Supabase.instance.client);
    _reload();
  }

  void _reload() {
    _roomFuture = _rooms.currentRoom();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _roomFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load Love Vault: ${snapshot.error}'),
              ),
            ),
          );
        }

        final room = snapshot.data;
        if (room != null) {
          return HomeShell(room: room);
        }

        return OnboardingScreen(
          roomService: _rooms,
          onConnected: () => setState(_reload),
        );
      },
    );
  }
}
