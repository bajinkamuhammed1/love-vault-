import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/room_service.dart';
import '../play/play_screen.dart';
import '../settings/settings_screen.dart';
import '../question_bank/question_bank_screen.dart';
import '../ask_me/ask_me_screen.dart';
import '../surprise/surprise_screen.dart';
import '../memories/memories_screen.dart';
import '../profile/profile_screen.dart';
import '../promises/promises_screen.dart';

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
  static const _labels = ['Us', 'Play', 'Ask', 'Memories', 'Surprises'];
  static const _icons = [Icons.favorite_border, Icons.casino_outlined, Icons.chat_bubble_outline, Icons.photo_outlined, Icons.card_giftcard_outlined];

  @override
  void initState() {
    super.initState();
    _room = Map.of(widget.room);
    _rooms = RoomService(Supabase.instance.client);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
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
        title: Text((_room['couple_title']?.toString().trim().isNotEmpty ?? false) ? _room['couple_title'].toString() : 'Love Vault'),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 4), child: Center(child: Text(connected ? 'Together' : 'Waiting', style: Theme.of(context).textTheme.labelLarge))),
          Builder(builder: (c) => IconButton(onPressed: () => Scaffold.of(c).openEndDrawer(), icon: const Icon(Icons.menu_rounded))),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text('Just the two of you', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())).then((_) => _refresh());
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: const Text('Question Bank'),
                subtitle: const Text('Topics and custom questions'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionBankScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.volunteer_activism_outlined),
                title: const Text('Our Promises'),
                subtitle: const Text('The words you choose together'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PromisesScreen(vaultId: id)));
                },
              ),
              const Divider(),
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
          _UsPage(room: _room),
          PlayScreen(roomId: id),
          AskMeScreen(roomId: id),
          MemoriesScreen(roomId: id),
          SurpriseScreen(roomId: id),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: List.generate(_labels.length, (i) => NavigationDestination(icon: Icon(_icons[i]), selectedIcon: Icon(_icons[i]), label: _labels[i])),
      ),
    );
  }
}

class _UsPage extends StatelessWidget {
  const _UsPage({required this.room});
  final Map<String, dynamic> room;

  DateTime? get _start => DateTime.tryParse(room['relationship_started_on']?.toString() ?? '');

  String _pretty(DateTime d) {
    const m = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  int _daysTogether(DateTime s) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).difference(DateTime(s.year, s.month, s.day)).inDays;
  }

  DateTime _anniversary(DateTime s, int y) {
    if (s.month == 2 && s.day == 29) {
      final leap = DateTime(y, 3, 0).day == 29;
      return DateTime(y, 2, leap ? 29 : 28);
    }
    return DateTime(y, s.month, s.day);
  }

  ({int days, DateTime date}) _next(DateTime s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var date = _anniversary(s, now.year);
    if (date.isBefore(today)) date = _anniversary(s, now.year + 1);
    return (days: date.difference(today).inDays, date: date);
  }

  @override
  Widget build(BuildContext context) {
    final members = (room['members'] as List?) ?? const [];
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final mineList = members.where((m) => m['user_id'] == uid).toList();
    final otherList = members.where((m) => m['user_id'] != uid).toList();
    final mine = mineList.isEmpty ? null : mineList.first;
    final other = otherList.isEmpty ? null : otherList.first;
    final myName = mine?['display_name']?.toString().trim();
    final otherName = other?['display_name']?.toString().trim();
    final nickname = mine?['nickname_for_partner']?.toString().trim() ?? '';
    final partnerName = nickname.isNotEmpty ? nickname : (otherName?.isNotEmpty == true ? otherName! : 'Partner');
    final myAvatar = mine?['avatar_emoji']?.toString() ?? '♥';
    final partnerAvatar = other?['avatar_emoji']?.toString() ?? '♥';
    final myBio = mine?['bio']?.toString().trim() ?? '';
    final partnerBio = other?['bio']?.toString().trim() ?? '';
    final start = _start;
    final next = start == null ? null : _next(start);
    final note = room['anniversary_note']?.toString().trim() ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        Text('Us', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text('The home of your story together.', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFEEF1), Color(0xFFFFF9F6)]),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _Person(avatar: myAvatar, name: myName?.isNotEmpty == true ? myName! : 'You', subtitle: myBio.isEmpty ? 'You' : myBio)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.favorite_rounded, color: Theme.of(context).colorScheme.primary)),
                  Expanded(child: _Person(avatar: partnerAvatar, name: partnerName, subtitle: partnerBio.isEmpty ? (other == null ? 'Waiting to connect' : 'Partner') : partnerBio)),
                ],
              ),
              if (start != null) ...[
                const SizedBox(height: 18),
                Text('Together since ${_pretty(start)}', style: Theme.of(context).textTheme.labelLarge),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), color: const Color(0xFFFFF1F4)),
          child: start == null
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Our anniversary', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  const Text('Add your relationship date in Profile to begin your shared timeline.'),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Icon(Icons.calendar_month_outlined), const SizedBox(width: 10), Text('Our anniversary', style: Theme.of(context).textTheme.titleLarge)]),
                  const SizedBox(height: 14),
                  Text(_pretty(start), style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _MiniStat(value: '${_daysTogether(start)}', label: 'days together')),
                    const SizedBox(width: 10),
                    Expanded(child: _MiniStat(value: next!.days == 0 ? 'Today' : '${next.days}', label: next.days == 0 ? 'anniversary' : 'days to go')),
                  ]),
                  if (note.isNotEmpty) ...[const SizedBox(height: 14), Text(note, style: Theme.of(context).textTheme.bodyLarge)],
                ]),
        ),
        const SizedBox(height: 18),
        _StoryCard(start: start),
      ],
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({required this.avatar, required this.name, required this.subtitle});
  final String avatar, name, subtitle;
  @override
  Widget build(BuildContext context) => Column(children: [
        CircleAvatar(radius: 31, child: Text(avatar, style: const TextStyle(fontSize: 24))),
        const SizedBox(height: 9),
        Text(name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 3),
        Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ]);
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.start});
  final DateTime? start;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.auto_stories_outlined), const SizedBox(width: 10), Text('Our story', style: Theme.of(context).textTheme.titleLarge)]),
        const SizedBox(height: 8),
        Text(start == null ? 'Your shared story begins here. Add your relationship date and memories as you build it together.' : 'From the day your story began to every memory you add, this is your shared home.'),
      ]),
    ),
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: BorderRadius.circular(18)),
    child: Column(children: [Text(value, style: Theme.of(context).textTheme.titleLarge), Text(label, textAlign: TextAlign.center)]),
  );
}
