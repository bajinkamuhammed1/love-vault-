import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/room_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.roomService,
    required this.onConnected,
  });

  final RoomService roomService;
  final VoidCallback onConnected;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (_code.text.trim().isEmpty) {
      setState(() => _error = 'Enter the pairing or recovery code.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.roomService.redeemPairingCode(
        _code.text,
        _name.text.trim().isEmpty ? 'Partner' : _name.text,
      );
      widget.onConnected();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().toLowerCase();
      setState(() {
        _error = message.contains('expired')
            ? 'That code is invalid or expired. Ask the Owner for a new one.'
            : 'Could not connect. Check the code and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child:CircleAvatar(radius:34,backgroundColor:Color(0xFFE9365A),child:Icon(Icons.lock_outline,color:Colors.white,size:32))),
                  const SizedBox(height: 20),
                  Text(
                    'Private Love Vault',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This account is signed in, but it is not connected to the private vault. Enter the one-time code from the Owner to continue.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFFFFF3F5),borderRadius:BorderRadius.circular(18)),child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.shield_outlined),SizedBox(width:10),Expanded(child:Text('First connection: use a pairing code. Lost access or a new sign-in: use a recovery code. A recovery code reconnects the same Partner profile and history.'))])),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _name,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: 'Your display name (first connection only)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _code,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Pairing or recovery code',
                      prefixIcon: Icon(Icons.key_outlined),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  FilledButton.icon(onPressed:_busy?null:_join,icon:const Icon(Icons.lock_open_outlined),label:Text(_busy?'Checking code…':'Unlock with code')),
                  const SizedBox(height:10),
                  TextButton.icon(onPressed:_busy?null:() async {await Supabase.instance.client.auth.signOut();},icon:const Icon(Icons.logout),label:const Text('Use a different account')),
                  const SizedBox(height:6),
                  const Text('A code works once and expires after 30 minutes.',textAlign:TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
