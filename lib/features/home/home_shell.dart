import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/room_service.dart';
import '../play/play_screen.dart';
import '../settings/settings_screen.dart';
import '../ask_me/ask_me_screen.dart';
import '../surprise/surprise_screen.dart';
import '../memories/memories_screen.dart';
import '../profile/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.room});
  final Map<String, dynamic> room;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final RoomService _rooms;
  late Map<String, dynamic> _room;
  Timer? _timer;

  static const _labels = ['Home', 'Play', 'Ask Me', 'Memories', 'Surprises'];
  static const _icons = [
    Icons.home_outlined,
    Icons.sports_esports_outlined,
    Icons.chat_bubble_outline,
    Icons.photo_outlined,
    Icons.card_giftcard_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _room = Map.of(widget.room);
    _rooms = RoomService(Supabase.instance.client);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final r = await _rooms.roomSnapshot(widget.room['id'].toString());
      if (mounted) setState(() => _room = r);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = (_room['members'] as List?) ?? const [];
    final connected = members.length >= 2;
    final id = _room['id'].toString();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 24,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFE9365A),
              child: Icon(Icons.favorite, color: Colors.white, size: 28),
            ),
            SizedBox(width: 13),
            Text('Love\nVault', style: TextStyle(fontSize: 27, height: .86, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: const Color(0xFFFFEFF2), borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 9, color: Color(0xFFE9365A)),
                const SizedBox(width: 7),
                Text(connected ? 'Connected' : 'Waiting', style: const TextStyle(color: Color(0xFFE9365A), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Builder(builder: (c) => IconButton(onPressed: () => Scaffold.of(c).openEndDrawer(), icon: const Icon(Icons.menu, size: 31))),
          const SizedBox(width: 10),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text('Love Vault', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              const Text('Private space for two'),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())).then((_) => _refresh());
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(roomId: id)));
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: [
          _HomePage(room: _room),
          PlayScreen(roomId: id),
          AskMeScreen(roomId: id),
          MemoriesScreen(roomId: id),
          SurpriseScreen(roomId: id),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: List.generate(
          _labels.length,
          (i) => NavigationDestination(icon: Icon(_icons[i]), selectedIcon: Icon(_icons[i]), label: _labels[i]),
        ),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.room});
  final Map<String, dynamic> room;

  DateTime? get _start => DateTime.tryParse(room['relationship_started_on']?.toString() ?? '');

  String _pretty(DateTime d) {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  int _daysTogether(DateTime start) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).difference(DateTime(start.year, start.month, start.day)).inDays;
  }

  ({int days, DateTime date}) _nextAnniversary(DateTime start) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(now.year, start.month, start.day);
    if (next.isBefore(today) || next == today) next = DateTime(now.year + 1, start.month, start.day);
    return (days: next.difference(today).inDays, date: next);
  }

  @override
  Widget build(BuildContext context) {
    final members = (room['members'] as List?) ?? const [];
    final connected = members.length >= 2;
    final code = room['room_code']?.toString() ?? '';
    final start = _start;
    final next = start == null ? null : _nextAnniversary(start);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 110),
      children: [
        Center(
          child: CircleAvatar(
            radius: 54,
            backgroundColor: const Color(0xFFFFD7E0),
            child: Icon(connected ? Icons.favorite : Icons.favorite_border, color: const Color(0xFF8C3E59), size: 55),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          connected ? 'Our Love Vault' : 'Your Love Vault is ready',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        Text(
          connected
              ? (start == null ? 'Your private space, just for the two of you.' : 'Together since ${_pretty(start)}')
              : 'Share your private code with your partner. This vault stays between the two of you.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (start != null) ...[
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(child: _StatCard(value: '${_daysTogether(start)}', label: 'days together')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(value: next == null ? '—' : '${next.days}', label: 'days to anniversary')),
            ],
          ),
        ],
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('YOUR PRIVATE VAULT', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 9),
                SelectableText(code, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final m in members)
                      Chip(
                        avatar: const Icon(Icons.person, size: 17),
                        label: Text(m['display_name']?.toString() ?? 'Partner'),
                      ),
                    if (!connected) const Chip(label: Text('Waiting for partner')),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (start != null && next != null) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F4),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.calendar_month_outlined, color: Color(0xFFE9365A)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Next anniversary', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 3),
                      Text('${_pretty(next.date)} • ${next.days} days to go'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        decoration: BoxDecoration(color: const Color(0xFFFFF1F4), borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 3),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
}
