import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ask_me_service.dart';

class AskMeScreen extends StatefulWidget {
  const AskMeScreen({super.key, required this.roomId});
  final String roomId;
  @override State<AskMeScreen> createState()=>_AskMeScreenState();
}

class _AskMeScreenState extends State<AskMeScreen> {
  late final AskMeService _service;
  late Future<List<Map<String,dynamic>>> _future;
  bool _busy=false;

  @override void initState(){super.initState();_service=AskMeService(Supabase.instance.client);_reload();}
  void _reload() {
    setState(() {
      _future = _service.questions(widget.roomId);
    });
  }

  Future<void> _compose() async {
    final partner=await _service.partner(widget.roomId);
    if(!mounted)return;
    if(partner==null){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Your partner needs to join first.')));
      return;
    }
    final created=await showModalBottomSheet<bool>(
      context:context,isScrollControlled:true,
      builder:(_)=>_ComposeAskSheet(service:_service,roomId:widget.roomId,partner:partner),
    );
    if(created==true)_reload();
  }

  Future<void> _answer(Map<String,dynamic> q) async {
    final result=await showModalBottomSheet<String>(
      context:context,isScrollControlled:true,
      builder:(_)=>_AnswerSheet(question:q),
    );
    if(result==null||result.trim().isEmpty)return;
    setState(()=>_busy=true);
    try{await _service.answer(q['id'].toString(),result);_reload();}
    catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not send your answer.')));}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      body:Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(24,28,24,14),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:const Color(0xFFFFEDF1),borderRadius:BorderRadius.circular(20)),child:const Icon(Icons.chat_bubble_outline,color:Color(0xFFE9365A),size:30)),
          const SizedBox(width:16),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Ask Me',style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:5),Text('Ask your partner something you really want to know.',style:Theme.of(context).textTheme.bodyLarge)])),
          FilledButton.icon(onPressed:_busy?null:_compose,icon:const Icon(Icons.add),label:const Text('Ask'))
        ])),
        Expanded(child:FutureBuilder<List<Map<String,dynamic>>>(
        future:_future,
        builder:(context,snapshot){
          if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
          if(snapshot.hasError)return Center(child:FilledButton.icon(onPressed:_reload,icon:const Icon(Icons.refresh),label:const Text('Try Again')));
          final items=snapshot.data??const[];
          if(items.isEmpty)return const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('No questions yet. Tap Ask to send your partner one.',textAlign:TextAlign.center)));
          return RefreshIndicator(onRefresh:()async=>_reload(),child:ListView.builder(
            padding:const EdgeInsets.fromLTRB(24,8,24,96),itemCount:items.length,
            itemBuilder:(context,i){
              final q=items[i], mine=q['asker_id']==_service.userId, answer=q['answer'];
              return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[Icon(mine?Icons.outbox_outlined:Icons.markunread_outlined),const SizedBox(width:8),Text(mine?'You asked':'Asked to you',style:Theme.of(context).textTheme.labelLarge)]),
                const SizedBox(height:10),Text(q['question_text']?.toString()??'',style:Theme.of(context).textTheme.titleMedium),
                const SizedBox(height:10),
                if(answer!=null)...[const Text('Answer'),const SizedBox(height:4),Text((answer as Map)['answer_text']?.toString()??'')]
                else if(!mine) FilledButton(onPressed:_busy?null:()=>_answer(q),child:const Text('Answer'))
                else const Text('Waiting for your partner…'),
              ])));
            },
          ));
        },
      )),
    ]));
  }
}

class _ComposeAskSheet extends StatefulWidget {
  const _ComposeAskSheet({required this.service,required this.roomId,required this.partner});
  final AskMeService service; final String roomId; final Map<String,dynamic> partner;
  @override State<_ComposeAskSheet> createState()=>_ComposeAskSheetState();
}
class _ComposeAskSheetState extends State<_ComposeAskSheet>{
  final _question=TextEditingController();
  final _options=List.generate(4,(_)=>TextEditingController());
  bool _multiple=false,_busy=false;
  @override void dispose(){_question.dispose();for(final c in _options)c.dispose();super.dispose();}
  Future<void> _send() async {
    final text=_question.text.trim(); final opts=_options.map((c)=>c.text.trim()).where((v)=>v.isNotEmpty).toList();
    if(text.isEmpty||(_multiple&&opts.length<2))return;
    setState(()=>_busy=true);
    try{
      await widget.service.create(roomId:widget.roomId,targetId:widget.partner['id'].toString(),text:text,answerType:_multiple?'multiple_choice':'text',options:_multiple?opts:null);
      if(mounted)Navigator.pop(context,true);
    }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not send the question.')));}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override Widget build(BuildContext context)=>Padding(
    padding:EdgeInsets.only(left:20,right:20,top:20,bottom:MediaQuery.viewInsetsOf(context).bottom+20),
    child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text('Ask ${widget.partner['display_name']??'your partner'}',style:Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height:16),TextField(controller:_question,maxLength:1000,minLines:2,maxLines:5,decoration:const InputDecoration(labelText:'Your question',border:OutlineInputBorder())),
      SwitchListTile.adaptive(contentPadding:EdgeInsets.zero,title:const Text('Multiple choice'),subtitle:const Text('Otherwise they can write their own answer.'),value:_multiple,onChanged:_busy?null:(v)=>setState(()=>_multiple=v)),
      if(_multiple)for(int i=0;i<_options.length;i++)Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:_options[i],decoration:InputDecoration(labelText:'Option ${i+1}',border:const OutlineInputBorder()))),
      const SizedBox(height:8),FilledButton.icon(onPressed:_busy?null:_send,icon:const Icon(Icons.send_outlined),label:const Text('Send Question')),
    ])),
  );
}

class _AnswerSheet extends StatefulWidget{
  const _AnswerSheet({required this.question}); final Map<String,dynamic> question;
  @override State<_AnswerSheet> createState()=>_AnswerSheetState();
}
class _AnswerSheetState extends State<_AnswerSheet>{
  final _text=TextEditingController(); String? _selected;
  @override void dispose(){_text.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    final multi=widget.question['answer_type']=='multiple_choice';
    final options=(widget.question['options'] as List?)?.map((e)=>e.toString()).toList()??const<String>[];
    return Padding(padding:EdgeInsets.only(left:20,right:20,top:20,bottom:MediaQuery.viewInsetsOf(context).bottom+20),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text(widget.question['question_text']?.toString()??'',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:16),
      if(multi)for(final option in options)RadioListTile<String>(title:Text(option),value:option,groupValue:_selected,onChanged:(v)=>setState(()=>_selected=v))
      else TextField(controller:_text,minLines:3,maxLines:6,maxLength:2000,decoration:const InputDecoration(labelText:'Your answer',border:OutlineInputBorder())),
      const SizedBox(height:12),FilledButton(onPressed:(){final value=multi?_selected:_text.text.trim();if(value!=null&&value.isNotEmpty)Navigator.pop(context,value);},child:const Text('Send Answer')),
    ])));
  }
}
