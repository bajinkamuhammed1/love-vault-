import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/play_service.dart';
class PlayScreen extends StatefulWidget{const PlayScreen({super.key,required this.roomId});final String roomId;@override State<PlayScreen> createState()=>_PlayScreenState();}
class _PlayScreenState extends State<PlayScreen>{
 late final PlayService _play;Map<String,dynamic>? _state;bool _busy=false;int _wheelTurns=0;String? _error;Timer? _poller;String? _choice,_guess;
 @override void initState(){super.initState();_play=PlayService(Supabase.instance.client);_discover();_poller=Timer.periodic(const Duration(seconds:2),(_)=>_discover());}
 Future<void> _discover()async{try{final id=await _play.currentSession(widget.roomId);if(id==null)return;final s=await _play.state(id);if(mounted)setState(()=>_state=s);}catch(_){}}
 @override void dispose(){_poller?.cancel();super.dispose();}
 Future<void> _spin()async{setState((){_busy=true;_error=null;_wheelTurns+=3;_choice=null;_guess=null;});try{await Future.delayed(const Duration(milliseconds:1100));final x=await _play.start(widget.roomId,guessEnabled:true);final s=await _play.state(x['session_id'].toString());if(mounted)setState(()=>_state=s);}catch(e){if(mounted)setState(()=>_error=_friendly(e.toString()));}finally{if(mounted)setState(()=>_busy=false);}}
 Future<void> _answer()async{final s=_state;if(s==null||_choice==null)return;await _act(()async{await _play.submitAnswer(s['session_id'].toString(),_choice!);await _discover();});}
 Future<void> _submitGuess()async{final s=_state;if(s==null||_guess==null)return;await _act(()async{await _play.submitGuess(s['session_id'].toString(),_guess!);await _discover();});}
 Future<void> _act(Future<void> Function() f)async{setState(()=>_busy=true);try{await f();}catch(e){if(mounted)setState(()=>_error=_friendly(e.toString()));}finally{if(mounted)setState(()=>_busy=false);}}
 String _friendly(String x){if(x.contains('partner has not joined'))return 'Your partner needs to join first.';if(x.contains('No enabled'))return 'Turn on at least one category in Settings.';return 'Could not continue. Please try again.';}
 Widget _options(List opts,String? selected,ValueChanged<String> onPick)=>Column(children:[for(final o in opts)Padding(padding:const EdgeInsets.only(bottom:10),child:Card(child:RadioListTile<String>(value:o.toString(),groupValue:selected,onChanged:_busy?null:(v){if(v!=null)onPick(v);},title:Text(o.toString()))))]);
 @override Widget build(BuildContext context){final s=_state;if(s==null)return Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
  TweenAnimationBuilder<double>(duration:const Duration(milliseconds:1100),tween:Tween(begin:0,end:_wheelTurns.toDouble()),builder:(c,v,ch)=>Transform.rotate(angle:v*6.28318,child:ch),child:const CircleAvatar(radius:50,child:Icon(Icons.casino_outlined,size:58))),const SizedBox(height:18),
  Text('Spin for your next question',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:8),const Text('You both get the same question and choices.',textAlign:TextAlign.center),const SizedBox(height:18),
  if(_error!=null)Text(_error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),FilledButton.icon(onPressed:_busy?null:_spin,icon:const Icon(Icons.casino),label:Text(_busy?'Spinning…':'Spin'))
 ])));
 final status=s['status']?.toString();final answered=s['my_answer']!=null;final guessed=s['my_guess']!=null;final revealed=status=='revealed'||status=='complete';final opts=(s['options'] as List?)??const[];final answers=(s['answers'] as List?)??const[];final guesses=(s['guesses'] as List?)??const[];
 return ListView(padding:const EdgeInsets.fromLTRB(24,28,24,110),children:[
  Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('PLAY TOGETHER  •  Question ${s['question_number']??1} of 6',style:Theme.of(context).textTheme.titleMedium),Text('${s['answer_count']??0}/2 answered')]),const SizedBox(height:12),
  Center(child:Text('${s['category_emoji']??''} ${s['category_name']??''}',style:Theme.of(context).textTheme.titleLarge)),const SizedBox(height:12),
  Container(padding:const EdgeInsets.all(26),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFFFFF0F3),Color(0xFFFFF8EE)]),borderRadius:BorderRadius.circular(28)),child:Text(s['question_text']?.toString()??'',style:Theme.of(context).textTheme.headlineMedium,textAlign:TextAlign.center)),const SizedBox(height:14),
  if(!answered)...[_options(opts,_choice,(v)=>setState(()=>_choice=v)),FilledButton.icon(onPressed:_choice==null||_busy?null:_answer,icon:const Icon(Icons.arrow_forward),label:const Text('Next'))]
  else if(status=='answering')...[
   const Icon(Icons.check_circle_outline,size:44),const SizedBox(height:8),Text('Answer saved. Waiting for your partner… (${s['answer_count']}/2)',textAlign:TextAlign.center)]
  else if(status=='guessing'&&!guessed)...[
   Text('Guess your partner’s answer',style:Theme.of(context).textTheme.titleLarge,textAlign:TextAlign.center),const SizedBox(height:6),const Text('Pick the choice you think your partner selected.',textAlign:TextAlign.center),const SizedBox(height:12),
   _options(opts,_guess,(v)=>setState(()=>_guess=v)),FilledButton.icon(onPressed:_guess==null||_busy?null:_submitGuess,icon:const Icon(Icons.psychology_alt_outlined),label:const Text('Next'))]
  else if(status=='guessing')...[
   const Icon(Icons.hourglass_top,size:44),const SizedBox(height:8),Text('Guess saved. Waiting for your partner… (${s['guess_count']}/2)',textAlign:TextAlign.center)]
  else if(revealed)...[
   Text('Reveal',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:8),
   for(final a in answers)Card(child:ListTile(leading:const Icon(Icons.favorite_outline),title:Text((a as Map)['display_name']?.toString()??'Player'),subtitle:Text(a['answer']?.toString()??''))),
   for(final g in guesses)Card(child:ListTile(leading:const Icon(Icons.psychology_alt_outlined),title:Text('${(g as Map)['guesser_name']??'Player'} guessed'),subtitle:Text(g['guess']?.toString()??''))),
   const SizedBox(height:12),FilledButton.icon(onPressed:_busy?null:_spin,icon:const Icon(Icons.arrow_forward),label:Text((s['question_number']??1)==6?'Start New Round':'Next Question'))
  ],
  if(_error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(_error!,textAlign:TextAlign.center,style:TextStyle(color:Theme.of(context).colorScheme.error)))
 ]);}
}