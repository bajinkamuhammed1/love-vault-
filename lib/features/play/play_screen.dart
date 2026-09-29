import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/play_service.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.roomId});
  final String roomId;
  @override State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late final PlayService _play;
  final _answer = TextEditingController();
  final _guess = TextEditingController();
  Map<String,dynamic>? _state;
  bool _busy=false, _guessMode=true;
  int _wheelTurns=0;
  String? _error;
  Timer? _poller;

  @override void initState(){super.initState();_play=PlayService(Supabase.instance.client);_discover();_poller=Timer.periodic(const Duration(seconds:2),(_)=>_discover());}
  Future<void> _discover() async {
    try {
      final id=await _play.currentSession(widget.roomId);
      if(id==null)return;
      final state=await _play.state(id);
      if(mounted)setState(()=>_state=state);
    } catch(_){}
  }
  @override void dispose(){_poller?.cancel();_answer.dispose();_guess.dispose();super.dispose();}

  Future<void> _spin() async {
    setState((){_busy=true;_error=null;_wheelTurns+=3;});
    try {
      final started=await _play.start(widget.roomId,guessEnabled:_guessMode);
      final id=started['session_id'].toString();
      final state=await _play.state(id);
      if(!mounted)return;
      setState(()=>_state=state); _startPolling(id);
    } catch(e){if(mounted)setState(()=>_error=_friendly(e.toString()));}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  void _startPolling(String id){
    _poller?.cancel();
    _poller=Timer.periodic(const Duration(seconds:2),(_)=>_refresh(id));
  }
  Future<void> _refresh(String id) async {
    try{
      final state=await _play.state(id);
      if(!mounted)return;
      setState(()=>_state=state);
      if(state['status']=='revealed'||state['status']=='complete')_poller?.cancel();
    }catch(_){}
  }
  Future<void> _submitAnswer() async {
    final s=_state;if(s==null||_answer.text.trim().isEmpty)return;
    await _action(() async {
      await _play.submitAnswer(s['session_id'].toString(),_answer.text);
      await _refresh(s['session_id'].toString());
    });
  }
  Future<void> _submitGuess() async {
    final s=_state;if(s==null||_guess.text.trim().isEmpty)return;
    await _action(() async {
      await _play.submitGuess(s['session_id'].toString(),_guess.text);
      await _refresh(s['session_id'].toString());
    });
  }
  Future<void> _action(Future<void> Function() fn) async {
    setState((){_busy=true;_error=null;});
    try{await fn();}catch(e){if(mounted)setState(()=>_error=_friendly(e.toString()));}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  String _friendly(String raw){
    if(raw.contains('partner has not joined'))return 'Your partner needs to join the room first.';
    if(raw.contains('No enabled'))return 'Turn on at least one question category in Settings.';
    return 'Could not continue the game. Please try again.';
  }

  @override Widget build(BuildContext context){
    final s=_state;
    if(s==null)return Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(
      mainAxisSize:MainAxisSize.min,children:[
        TweenAnimationBuilder<double>(duration:const Duration(milliseconds:1100),tween:Tween(begin:0,end:_wheelTurns.toDouble()),builder:(context,v,child)=>Transform.rotate(angle:v*6.28318,child:child),child:const CircleAvatar(radius:48,child:Icon(Icons.casino_outlined,size:58))),const SizedBox(height:16),
        Text('Spin for a question',style:Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height:8),const Text('The spinner chooses from categories enabled for your room.'),
        const SizedBox(height:16),
        SwitchListTile.adaptive(
          title:const Text('Guess Mode'),
          subtitle:const Text('After answering, guess what your partner wrote before the reveal.'),
          value:_guessMode,onChanged:_busy?null:(v)=>setState(()=>_guessMode=v),
        ),
        if(_error!=null)Text(_error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
        const SizedBox(height:12),
        FilledButton.icon(onPressed:_busy?null:_spin,icon:const Icon(Icons.casino),label:const Text('Spin')),
      ])));

    final status=s['status']?.toString();
    final answered=s['my_answer']!=null;
    final guessed=s['my_guess']!=null;
    final revealed=status=='revealed'||status=='complete';
    final answers=(s['answers'] as List?)??const[];
    final guesses=(s['guesses'] as List?)??const[];

    return ListView(padding:const EdgeInsets.all(24),children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('Question ${s['question_number'] ?? 1} of 6',style:Theme.of(context).textTheme.titleMedium),Text('${s['answer_count'] ?? 0}/2 answered')]),
      const SizedBox(height:14),
      Center(child:Text('${s['category_emoji']??''} ${s['category_name']??''}',style:Theme.of(context).textTheme.titleLarge)),
      const SizedBox(height:18),
      Card(child:Padding(padding:const EdgeInsets.all(20),child:Text(s['question_text']?.toString()??'',style:Theme.of(context).textTheme.headlineSmall,textAlign:TextAlign.center))),
      const SizedBox(height:20),
      if(!answered)...[
        TextField(controller:_answer,minLines:3,maxLines:6,maxLength:2000,decoration:const InputDecoration(labelText:'Your answer',border:OutlineInputBorder())),
        FilledButton(onPressed:_busy?null:_submitAnswer,child:const Text('Lock In Answer')),
      ] else if(status=='answering')...[
        const Center(child:Icon(Icons.lock_clock_outlined,size:44)),const SizedBox(height:10),
        Text('Answer locked in. Waiting for your partner… (${s['answer_count']}/2)',textAlign:TextAlign.center),
      ] else if(status=='guessing'&&!guessed)...[
        Text('Guess time',style:Theme.of(context).textTheme.titleLarge,textAlign:TextAlign.center),
        const SizedBox(height:8),
        const Text('What do you think your partner answered?',textAlign:TextAlign.center),
        const SizedBox(height:16),
        TextField(controller:_guess,minLines:2,maxLines:5,maxLength:2000,decoration:const InputDecoration(labelText:'Your guess',border:OutlineInputBorder())),
        FilledButton.icon(onPressed:_busy?null:_submitGuess,icon:const Icon(Icons.psychology_alt_outlined),label:const Text('Lock In Guess')),
      ] else if(status=='guessing')...[
        const Center(child:Icon(Icons.lock_outline,size:44)),const SizedBox(height:10),
        Text('Guess locked in. Waiting for your partner… (${s['guess_count']}/2)',textAlign:TextAlign.center),
      ] else if(revealed)...[
        Text('Answer reveal',style:Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:10),
        for(final item in answers) Card(child:ListTile(
          title:Text((item as Map)['display_name']?.toString()??'Player'),
          subtitle:Text(item['answer']?.toString()??''),
        )),
        if(guesses.isNotEmpty)...[
          const SizedBox(height:12),Text('Guesses',style:Theme.of(context).textTheme.titleLarge),
          for(final item in guesses) Card(child:ListTile(
            leading:const Icon(Icons.psychology_alt_outlined),
            title:Text('${(item as Map)['guesser_name']??'Player'} guessed for ${item['target_name']??'partner'}'),
            subtitle:Text(item['guess']?.toString()??''),
          )),
        ],
        const SizedBox(height:16),
        OutlinedButton.icon(onPressed:_busy?null:(){_answer.clear();_guess.clear();setState(()=>_state=null);},icon:const Icon(Icons.refresh),label:Text((s['question_number']??1)==6?'Start New Round':'Next Question')),
      ],
      if(_error!=null)...[const SizedBox(height:12),Text(_error!,textAlign:TextAlign.center,style:TextStyle(color:Theme.of(context).colorScheme.error))],
    ]);
  }
}
