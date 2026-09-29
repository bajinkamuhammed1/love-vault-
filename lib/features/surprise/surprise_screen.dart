import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/surprise_service.dart';

class SurpriseScreen extends StatefulWidget{
  const SurpriseScreen({super.key,required this.roomId}); final String roomId;
  @override State<SurpriseScreen> createState()=>_SurpriseScreenState();
}
class _SurpriseScreenState extends State<SurpriseScreen>{
  late final SurpriseService _service; late Future<List<Map<String,dynamic>>> _future;
  @override void initState(){super.initState();_service=SurpriseService(Supabase.instance.client);_reload();}
  void _reload() {
    setState(() {
      _future = _service.list(widget.roomId);
    });
  }

  Future<void> _compose() async{
    final p=await _service.partner(widget.roomId); if(!mounted)return;
    if(p==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Your partner needs to join first.')));return;}
    final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,builder:(_)=>_ComposeSurprise(service:_service,roomId:widget.roomId,partner:p));
    if(ok==true)_reload();
  }

  Future<void> _open(Map<String,dynamic> item) async{
    if(item['is_locked']==true)return;
    if(item['recipient_id']==_service.userId && item['opened_at']==null){await _service.markOpened(item['id'].toString());_reload();}
    if(!mounted)return;
    await showDialog(context:context,builder:(context)=>AlertDialog(
      title:Text(item['title']?.toString()??'Surprise'),
      content:SingleChildScrollView(child:Text(item['body']?.toString()??'')),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Close'))],
    ));
  }

  @override Widget build(BuildContext context)=>Scaffold(
    body:FutureBuilder<List<Map<String,dynamic>>>(future:_future,builder:(context,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return Center(child:FilledButton.icon(onPressed:_reload,icon:const Icon(Icons.refresh),label:const Text('Try Again')));
      final items=s.data??const[];
      if(items.isEmpty)return const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('No surprises yet. Create a private text surprise for your partner.',textAlign:TextAlign.center)));
      return RefreshIndicator(onRefresh:()async=>_reload(),child:ListView.builder(
        padding:const EdgeInsets.fromLTRB(16,16,16,96),itemCount:items.length,itemBuilder:(context,i){
          final x=items[i],mine=x['sender_id']==_service.userId,locked=x['is_locked']==true;
          final reveal=x['reveal_at']==null?null:DateTime.tryParse(x['reveal_at'].toString())?.toLocal();
          return Card(child:ListTile(
            leading:Icon(locked?Icons.lock_clock_outlined:(mine?Icons.outbox_outlined:Icons.card_giftcard)),
            title:Text(x['title']?.toString()??'Surprise'),
            subtitle:Text(locked&&reveal!=null?'Unlocks ${_format(reveal)}':mine?'Sent to your partner':x['opened_at']==null?'Ready to open':'Opened'),
            trailing:locked?null:const Icon(Icons.chevron_right),onTap:locked?null:()=>_open(x),
          ));
        },
      ));
    }),
    floatingActionButton:FloatingActionButton.extended(onPressed:_compose,icon:const Icon(Icons.add),label:const Text('New Surprise')),
  );
  String _format(DateTime d)=>'${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}

class _ComposeSurprise extends StatefulWidget{
  const _ComposeSurprise({required this.service,required this.roomId,required this.partner});
  final SurpriseService service;final String roomId;final Map<String,dynamic> partner;
  @override State<_ComposeSurprise> createState()=>_ComposeSurpriseState();
}
class _ComposeSurpriseState extends State<_ComposeSurprise>{
  final _title=TextEditingController(),_body=TextEditingController(); DateTime? _reveal; bool _busy=false;
  @override void dispose(){_title.dispose();_body.dispose();super.dispose();}
  Future<void> _pick() async{
    final now=DateTime.now(); final date=await showDatePicker(context:context,firstDate:now,lastDate:DateTime(now.year+2),initialDate:_reveal??now);
    if(date==null||!mounted)return;
    final time=await showTimePicker(context:context,initialTime:TimeOfDay.fromDateTime(_reveal??now.add(const Duration(hours:1))));
    if(time==null)return;
    setState(()=>_reveal=DateTime(date.year,date.month,date.day,time.hour,time.minute));
  }
  Future<void> _send() async{
    if(_title.text.trim().isEmpty||_body.text.trim().isEmpty)return;
    if(_reveal!=null&&!_reveal!.isAfter(DateTime.now())){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Choose a future reveal time.')));return;}
    setState(()=>_busy=true);
    try{await widget.service.create(roomId:widget.roomId,recipientId:widget.partner['id'].toString(),title:_title.text,body:_body.text,revealAt:_reveal);if(mounted)Navigator.pop(context,true);}
    catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not create the surprise.')));}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override Widget build(BuildContext context)=>Padding(
    padding:EdgeInsets.only(left:20,right:20,top:20,bottom:MediaQuery.viewInsetsOf(context).bottom+20),
    child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text('Surprise ${widget.partner['display_name']??'your partner'}',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:16),
      TextField(controller:_title,maxLength:120,decoration:const InputDecoration(labelText:'Title',border:OutlineInputBorder())),const SizedBox(height:8),
      TextField(controller:_body,maxLength:5000,minLines:4,maxLines:8,decoration:const InputDecoration(labelText:'Message',border:OutlineInputBorder())),
      ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.schedule),title:Text(_reveal==null?'Reveal immediately':'Scheduled reveal'),subtitle:Text(_reveal==null?'Your partner can open it right away':_reveal.toString()),trailing:IconButton(onPressed:_pick,icon:const Icon(Icons.edit_calendar))),
      if(_reveal!=null)TextButton(onPressed:()=>setState(()=>_reveal=null),child:const Text('Remove schedule')),
      FilledButton.icon(onPressed:_busy?null:_send,icon:const Icon(Icons.card_giftcard),label:const Text('Create Surprise')),
    ])),
  );
}
