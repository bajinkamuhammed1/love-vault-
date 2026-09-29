import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/room_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final RoomService _rooms;
  final _name = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _rooms = RoomService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await _rooms.myProfile();
      if (!mounted) return;
      _name.text = profile['display_name']?.toString() ?? '';
    } catch (_) {
      if (!mounted) return;
      _loadError = 'We couldn’t load your profile. Check your connection and try again.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final displayName = _name.text.trim();
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a display name before saving.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _rooms.updateDisplayName(displayName);
      if (!mounted) return;
      _name.text = displayName;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We couldn’t update your name. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Your Profile'),
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 42,
                            color: Color(0xFFE9365A),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Center(
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: Color(0xFFFFEDF1),
                          child: Icon(
                            Icons.favorite_outline,
                            size: 46,
                            color: Color(0xFFE9365A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Your side of the vault',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'This is the name your partner sees.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _name,
                        maxLength: 50,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.check),
                        label: Text(_saving ? 'Saving…' : 'Save changes'),
                      ),
                      const SizedBox(height: 24),
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: Color(0xFFE9365A),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Your profile belongs to this private two-person Love Vault.',
                                  style: TextStyle(fontFamily: 'sans-serif'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      );
}
