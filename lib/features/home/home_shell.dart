import 'package:flutter/material.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

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
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: const [
              ListTile(
                leading: Icon(Icons.favorite_outline),
                title: Text('Love Vault'),
                subtitle: Text('Private room for two'),
              ),
              Divider(),
              ListTile(leading: Icon(Icons.person_outline), title: Text('Profile')),
              ListTile(leading: Icon(Icons.settings_outlined), title: Text('Settings')),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _PlaceholderPage(
            icon: Icons.favorite_outline,
            title: 'Your private space',
            text: 'Connect your room to start sharing questions and memories.',
          ),
          _PlaceholderPage(
            icon: Icons.casino_outlined,
            title: 'Play',
            text: 'Spin an enabled category and answer the same question together.',
          ),
          _PlaceholderPage(
            icon: Icons.question_answer_outlined,
            title: 'Ask Me',
            text: 'Send a written or multiple-choice question to your partner.',
          ),
          _PlaceholderPage(
            icon: Icons.card_giftcard_outlined,
            title: 'Surprise',
            text: 'Create a text surprise that can be revealed later.',
          ),
          _PlaceholderPage(
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
