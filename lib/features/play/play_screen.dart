import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/play_service.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key,required this.roomId});
  final String roomId;
  @override State<PlayScreen> createState()=>_PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late final PlayService _play;
  Map<String,dynamic>? _game;
  List<Map<String,dynamic>> _categories=[];
  int _index=0;
  bool _busy=false;
  String? _error;
  Timer? _poller;

  @override void initState(){super.initState();_play=PlayService(Supabase.instance.client);_load();_poller=Timer.periodic(const Duration(seconds:2),(_)=>_refresh());}
  @override void dispose(){_poller?.cancel();super.dispose();}

  Future<void> _load() async {
    try {
      final cats=await _play.categories(widget.roomId);
      final id=await _play.currentGame(widget.roomId);
      Map<String,dynamic>? game;
      if(id!=null) game=await _play.gameState(id);
      if(mounted)setState((){_categories=cats;_game=game;_index=_firstOpen(game);});
    }catch(e){if(mounted)setState(()=>_error='Could not load Play.');}
  }
  Future<void> _refresh() async {
    final g=_game;if(g==null)return;
    try{final n=await _play.gameState(g['game_id'].toString());if(mounted)setState((){_game=n;_index=_firstOpen(n,preferred:_index);});}catch(_){}
  }
  int _firstOpen(Map<String,dynamic>? g,{int preferred=0}){
    if(g==null)return 0;final qs=(g['questions'] as List?)??[];
    if(qs.isEmpty)return 0;final status=g['status'];
    if(status=='answering'){for(var i=0;i<qs.length;i++){if((qs[i] as Map)['my_answer']==null)return i;}}
    if(status=='guessing'){for(var i=0;i<qs.length;i++){if((qs[i] as Map)['my_guess']==null)return i;}}
    return preferred.clamp(0,qs.length-1);
  }
  Future<void> _spinAndStart() async {
    if(_categories.isEmpty)return;
    setState((){_busy=true;_error=null;});
    try{
      final nextId=await _play.nextCategory(widget.roomId);
      final cat=_categories.firstWhere((x)=>(x['id'] as num).toInt()==nextId,orElse:()=>_categories.first);
      if(mounted){await showDialog<void>(context:context,barrierDismissible:false,builder:(context)=>_SpinDialog(category:cat));}
      if(!mounted)return;
      await _start(cat,manageBusy:false);
    }catch(_){if(mounted)setState(()=>_error='Could not start the game. Please try again.');}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _start(Map<String,dynamic> cat,{bool manageBusy=true}) async {
    if(manageBusy)setState((){_busy=true;_error=null;});
    try{final id=await _play.startCategory(widget.roomId,(cat['id'] as num).toInt());final g=await _play.gameState(id);if(mounted)setState((){_game=g;_index=0;});}
    catch(e){if(mounted)setState(()=>_error=e.toString().contains('partner')?'Your partner needs to join first.':'Could not start this category.');}
    finally{if(manageBusy&&mounted)setState(()=>_busy=false);}
  }
  Future<void> _pick(String value) async {
    final g=_game;if(g==null)return;final qs=(g['questions'] as List);final q=Map<String,dynamic>.from(qs[_index] as Map);
    setState(()=>_busy=true);
    try{
      if(g['status']=='answering')await _play.saveAnswer(g['game_id'].toString(),(q['question_id'] as num).toInt(),value);
      else if(g['status']=='guessing')await _play.saveGuess(g['game_id'].toString(),(q['question_id'] as num).toInt(),value);
      final n=await _play.gameState(g['game_id'].toString());
      if(mounted)setState((){_game=n;_index=_firstOpen(n,preferred:(_index+1).clamp(0,qs.length-1));});
    }catch(_){if(mounted)setState(()=>_error='Could not save that choice.');}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _quit() async {
    final g=_game;if(g==null)return;
    await _play.quit(g['game_id'].toString());
    if(mounted)setState((){_game=null;_index=0;});
  }

  @override Widget build(BuildContext context){
    final g=_game;
    if(g==null)return _categoryPicker(context);
    final qs=(g['questions'] as List?)??[];
    if(qs.isEmpty)return const Center(child:Text('No questions available.'));
    _index=_index.clamp(0,qs.length-1);
    final q=Map<String,dynamic>.from(qs[_index] as Map);
    final status=g['status']?.toString()??'answering';
    final cat=Map<String,dynamic>.from((g['category'] as Map?)??{});
    final options=(q['options'] as List?)??const[];
    final selected=status=='answering'?q['my_answer']?.toString():q['my_guess']?.toString();

    return ListView(padding:const EdgeInsets.fromLTRB(22,20,22,110),children:[
      Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('${cat['emoji']??''} ${cat['name']??'Play'}',style:Theme.of(context).textTheme.headlineSmall),
          Text(status=='answering'?'Answer your questions':'Guess your partner’s answers',style:Theme.of(context).textTheme.bodyMedium),
        ])),
        TextButton.icon(onPressed:_busy?null:_quit,icon:const Icon(Icons.close,size:17),label:const Text('Leave')),
      ]),
      const SizedBox(height:16),
      LinearProgressIndicator(value:(_index+1)/qs.length,borderRadius:BorderRadius.circular(10)),
      const SizedBox(height:8),
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        Text('Question ${_index+1} of ${qs.length}'),
        Text(status=='answering'?'${g['my_answer_count']}/${qs.length} answered':'${g['my_guess_count']}/${qs.length} guessed'),
      ]),
      const SizedBox(height:20),
      Container(padding:const EdgeInsets.all(26),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFFFFF0F3),Color(0xFFFFF8EE)]),borderRadius:BorderRadius.circular(28)),child:Text(q['text']?.toString()??'',style:Theme.of(context).textTheme.headlineSmall,textAlign:TextAlign.center)),
      const SizedBox(height:18),
      if(status=='answering'||status=='guessing')
        for(final o in options)Padding(padding:const EdgeInsets.only(bottom:10),child:InkWell(
          onTap:_busy?null:()=>_pick(o.toString()),borderRadius:BorderRadius.circular(20),
          child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:selected==o.toString()?const Color(0xFFFFEDF1):Colors.white,border:Border.all(color:selected==o.toString()?const Color(0xFFE9365A):const Color(0xFFE9E4E5)),borderRadius:BorderRadius.circular(20)),child:Row(children:[Icon(selected==o.toString()?Icons.radio_button_checked:Icons.radio_button_off,color:selected==o.toString()?const Color(0xFFE9365A):const Color(0xFF8A8587)),const SizedBox(width:12),Expanded(child:Text(o.toString()))])),
        )),
      if(status=='answering'&&(g['my_answer_count'] as num).toInt()==qs.length&&(g['partner_answer_count'] as num).toInt()<qs.length)
        const _WaitCard(text:'Your answers are complete. Your partner is still answering.'),
      if(status=='guessing'&&(g['my_guess_count'] as num).toInt()==qs.length&&(g['partner_guess_count'] as num).toInt()<qs.length)
        const _WaitCard(text:'Your guesses are complete. Waiting for your partner.'),
      if(status=='revealed')...[
        Builder(builder:(context){final guess=q['my_guess']?.toString();final answer=q['partner_answer']?.toString();final correct=guess==answer;return Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:correct?const Color(0xFFF1FAF3):const Color(0xFFFFF1F4),borderRadius:BorderRadius.circular(24)),child:Column(children:[Icon(correct?Icons.check_circle:Icons.cancel_outlined,size:44,color:correct?Colors.green:const Color(0xFFE9365A)),const SizedBox(height:8),Text(correct?'Correct':'Not quite',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:5),Text(correct?'Your partner chose “$answer”.':'Your partner chose “$answer” instead.',textAlign:TextAlign.center)]));}),
      ],
      if(qs.length>1)Padding(padding:const EdgeInsets.only(top:14),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        IconButton.filledTonal(onPressed:_index>0?()=>setState(()=>_index--):null,icon:const Icon(Icons.arrow_back)),
        if(status=='revealed')Text('${_index+1} / ${qs.length}'),
        IconButton.filledTonal(onPressed:_index<qs.length-1?()=>setState(()=>_index++):null,icon:const Icon(Icons.arrow_forward)),
      ])),
      if(_error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(_error!,textAlign:TextAlign.center,style:TextStyle(color:Theme.of(context).colorScheme.error))),
    ]);
  }

  Widget _categoryPicker(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(22,34,22,110),children:[
    const SizedBox(height:28),
    const Center(child:Text('💕',style:TextStyle(fontSize:54))),
    const SizedBox(height:16),
    Text('Ready to play?',textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineMedium),
    const SizedBox(height:8),
    Text('Spin for your next game. Your enabled categories stay private in Settings and Love Vault keeps the games moving in order without repeating the same category.',textAlign:TextAlign.center,style:Theme.of(context).textTheme.bodyLarge),
    const SizedBox(height:30),
    Center(child:SizedBox(width:210,height:210,child:DecoratedBox(decoration:BoxDecoration(shape:BoxShape.circle,color:const Color(0xFFFFEDF1),border:Border.all(color:const Color(0xFFE9365A),width:3)),child:const Center(child:Icon(Icons.favorite,size:70,color:Color(0xFFE9365A)))))),
    const SizedBox(height:28),
    FilledButton.icon(onPressed:_busy||_categories.isEmpty?null:_spinAndStart,icon:const Icon(Icons.casino_outlined),label:Text(_busy?'Choosing your game…':'Spin & Play')),
    if(_categories.isEmpty&&!_busy)const Padding(padding:EdgeInsets.all(20),child:Text('Enable at least one category in Settings to play.',textAlign:TextAlign.center)),
    if(_error!=null)Padding(padding:const EdgeInsets.only(top:14),child:Text(_error!,textAlign:TextAlign.center,style:TextStyle(color:Theme.of(context).colorScheme.error))),
  ]);
}

class _WaitCard extends StatelessWidget{
  const _WaitCard({required this.text});final String text;
  @override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(top:12),padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:const Color(0xFFFFF1F4),borderRadius:BorderRadius.circular(22)),child:Row(children:[const Icon(Icons.favorite_outline,color:Color(0xFFE9365A)),const SizedBox(width:12),Expanded(child:Text(text))]));
}


class _SpinDialog extends StatefulWidget{const _SpinDialog({required this.category});final Map<String,dynamic> category;@override State<_SpinDialog> createState()=>_SpinDialogState();}
class _SpinDialogState extends State<_SpinDialog>{Timer? t;@override void initState(){super.initState();t=Timer(const Duration(milliseconds:1100),(){if(mounted)Navigator.pop(context);});}@override void dispose(){t?.cancel();super.dispose();}@override Widget build(BuildContext context)=>AlertDialog(content:Padding(padding:const EdgeInsets.symmetric(vertical:24),child:Column(mainAxisSize:MainAxisSize.min,children:[const SizedBox(width:70,height:70,child:CircularProgressIndicator(strokeWidth:7)),const SizedBox(height:24),Text('Spinning…',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:8),const Text('Finding your next game',textAlign:TextAlign.center)])));}
