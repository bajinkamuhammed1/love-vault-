import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/memory_service.dart';

class MemoriesScreen extends StatefulWidget{
  const MemoriesScreen({super.key,required this.roomId}); final String roomId;
  @override State<MemoriesScreen> createState()=>_MemoriesScreenState();
}
class _MemoriesScreenState extends State<MemoriesScreen>{
  late final MemoryService _service; late Future<List<Map<String,dynamic>>> _future;
  @override void initState(){super.initState();_service=MemoryService(Supabase.instance.client);_reload();}
  void _reload() {\n    setState(() {\n      _future = _service.list(widget.roomId);\n    });\n  }

  Future<void> _edit([Map<String,dynamic>? memory]) async{
    final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,builder:(_)=>_MemoryEditor(service:_service,roomId:widget.roomId,memory:memory));
    if(ok==true)_reload();
  }
  Future<void> _delete(Map<String,dynamic> m) async{
    final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Delete memory?'),content:const Text('This removes the memory from your shared vault.'),actions:[
      TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),
      FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Delete')),
    ]));
    if(yes==true){try{await _service.delete(m['id'].toString());_reload();}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not delete the memory.')));}}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    body:FutureBuilder<List<Map<String,dynamic>>>(future:_future,builder:(context,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return Center(child:FilledButton.icon(onPressed:_reload,icon:const Icon(Icons.refresh),label:const Text('Try Again')));
      final items=s.data??const[];
      if(items.isEmpty)return const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('No memories yet. Save a meaningful moment as text.',textAlign:TextAlign.center)));
      return RefreshIndicator(onRefresh:()async=>_reload(),child:ListView.builder(padding:const EdgeInsets.fromLTRB(16,16,16,96),itemCount:items.length,itemBuilder:(context,i){
        final m=items[i],mine=m['author_id']==_service.userId;
        return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Expanded(child:Text(m['title']?.toString()??'',style:Theme.of(context).textTheme.titleMedium)),if(mine)PopupMenuButton<String>(onSelected:(v)=>v=='edit'?_edit(m):_delete(m),itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:'delete',child:Text('Delete'))])]),
          Text(_pretty(m['memory_date']?.toString()??''),style:Theme.of(context).textTheme.labelMedium),const SizedBox(height:8),
          Text(m['body']?.toString()??''),
        ])));
      }));
    }),
    floatingActionButton:FloatingActionButton.extended(onPressed:()=>_edit(),icon:const Icon(Icons.add),label:const Text('Add Memory')),
  );
  String _pretty(String raw){final d=DateTime.tryParse(raw);return d==null?raw:'${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';}
}

class _MemoryEditor extends StatefulWidget{
  const _MemoryEditor({required this.service,required this.roomId,this.memory});
  final MemoryService service; final String roomId; final Map<String,dynamic>? memory;
  @override State<_MemoryEditor> createState()=>_MemoryEditorState();
}
class _MemoryEditorState extends State<_MemoryEditor>{
  late final TextEditingController _title,_body; late DateTime _date; bool _busy=false;
  @override void initState(){super.initState();_title=TextEditingController(text:widget.memory?['title']?.toString()??'');_body=TextEditingController(text:widget.memory?['body']?.toString()??'');_date=DateTime.tryParse(widget.memory?['memory_date']?.toString()??'')??DateTime.now();}
  @override void dispose(){_title.dispose();_body.dispose();super.dispose();}
  Future<void> _pick() async{final d=await showDatePicker(context:context,firstDate:DateTime(2000),lastDate:DateTime.now(),initialDate:_date);if(d!=null)setState(()=>_date=d);}
  Future<void> _save() async{
    if(_title.text.trim().isEmpty||_body.text.trim().isEmpty)return;setState(()=>_busy=true);
    try{
      if(widget.memory==null)await widget.service.create(roomId:widget.roomId,title:_title.text,body:_body.text,date:_date);
      else await widget.service.update(id:widget.memory!['id'].toString(),title:_title.text,body:_body.text,date:_date);
      if(mounted)Navigator.pop(context,true);
    }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not save the memory.')));}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override Widget build(BuildContext context)=>Padding(padding:EdgeInsets.only(left:20,right:20,top:20,bottom:MediaQuery.viewInsetsOf(context).bottom+20),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text(widget.memory==null?'Add Memory':'Edit Memory',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:16),
    TextField(controller:_title,maxLength:120,decoration:const InputDecoration(labelText:'Title',border:OutlineInputBorder())),const SizedBox(height:8),
    TextField(controller:_body,maxLength:5000,minLines:4,maxLines:8,decoration:const InputDecoration(labelText:'Memory',border:OutlineInputBorder())),
    ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.calendar_today_outlined),title:const Text('Memory date'),subtitle:Text('${_date.day}/${_date.month}/${_date.year}'),trailing:IconButton(onPressed:_pick,icon:const Icon(Icons.edit_calendar))),
    FilledButton.icon(onPressed:_busy?null:_save,icon:const Icon(Icons.save_outlined),label:Text(widget.memory==null?'Save Memory':'Save Changes')),
  ])));
}
