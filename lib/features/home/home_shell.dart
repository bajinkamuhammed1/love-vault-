import 'package:flutter/material.dart';

import '../play/play_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.room});

  final Map<String, dynamic> room;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = ['Home', 'Play', 'Ask Me', 'Surprise', 'Memories'];
  static const _icons = [
    Icons.home_outlined,
    Icons.casino_outlined,
    Icons.question_answer_outlined,
    Icons.card_giftcard_outlined,
    Icons.auto_stories_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final roomCode = widget.room['room_code']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: const Text('Love Vault'),
                subtitle: Text('Room $roomCode'),
              ),
              const Divider(),
              const ListTile(leading: Icon(Icons.person_outline), title: Text('Profile')),
              const ListTile(leading: Icon(Icons.settings_outlined), title: Text('Settings')),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: [
          _HomePage(roomCode: roomCode, connected: widget.room['is_locked'] == true),
          PlayScreen(roomId: widget.room['id'].toString()),
          const _PlaceholderPage(
            icon: Icons.question_answer_outlined,
            title: 'Ask Me',
            text: 'Send a written or multiple-choice question to your partner.',
          ),
          const _PlaceholderPage(
            icon: Icons.card_giftcard_outlined,
            title: 'Surprise',
            text: 'Create a text surprise that can be revealed later.',
          ),
          const _PlaceholderPage(
            icon: Icons.auto_stories_outlined,
            title: 'Memories',
            text: 'Save meaningful text memories together.',
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: List.generate(
          _titles.length,
          (i) => NavigationDestination(icon: Icon(_icons[i]), label: _titles[i]),
        ),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.roomCode, required this.connected});

  final String roomCode;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(connected ? Icons.favorite : Icons.hourglass_top, size: 56),
              const SizedBox(height: 16),
              Text(
                connected ? 'You are connected' : 'Waiting for your partner',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text('Private room code'),
              const SizedBox(height: 6),
              SelectableText(
                roomCode,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                connected
                    ? 'Your private Love Vault is ready.'
                    : 'Share this code with your partner so they can join.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(text, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
