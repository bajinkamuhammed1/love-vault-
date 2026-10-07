import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/memory_service.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key, required this.roomId});
  final String roomId;
  @override State<MemoriesScreen> createState()=>_MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  late final MemoryService _service;
  late Future<List<Map<String,dynamic>>> _future;
  @override void initState(){super.initState();_service=MemoryService(Supabase.instance.client);_reload();}
  void _reload(){setState(()=>_future=_service.list(widget.roomId));}
  Future<void> _edit([Map<String,dynamic>? memory]) async {
    final ok=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,useSafeArea:true,builder:(_)=>_Editor(service:_service,roomId:widget.roomId,memory:memory));
    if(ok==true)_reload();
  }
  Future<void> _delete(Map<String,dynamic> m) async {
    final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Delete memory?'),content:const Text('This removes the memory from your shared story.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Delete'))]));
    if(yes!=true)return;
    try{await _service.delete(m['id'].toString());_reload();}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not delete that memory.')));}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    floatingActionButton:FloatingActionButton.extended(onPressed:()=>_edit(),icon:const Icon(Icons.add),label:const Text('New memory')),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:_future,builder:(context,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return Center(child:FilledButton.icon(onPressed:_reload,icon:const Icon(Icons.refresh),label:const Text('Try again')));
      final memories=s.data??<Map<String,dynamic>>[];
      final featured=memories.where((m)=>m['is_featured']==true).toList();
      final today=DateTime.now();
      final onThisDay=memories.where((m){final d=DateTime.tryParse(m['memory_date']?.toString()??'');return d!=null&&d.month==today.month&&d.day==today.day&&d.year!=today.year;}).toList();
      return RefreshIndicator(onRefresh:()async=>_reload(),child:ListView(padding:const EdgeInsets.fromLTRB(22,28,22,120),children:[
        Text('Our Memories',style:Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height:6),
        const Text('A timeline of the moments that became part of your story.'),
        const SizedBox(height:24),
        if(onThisDay.isNotEmpty)...[
          _Spotlight(title:'On this day',icon:Icons.history_rounded,memory:onThisDay.first,pretty:_pretty),
          const SizedBox(height:18),
        ],
        if(featured.isNotEmpty)...[
          _Spotlight(title:'Featured memory',icon:Icons.auto_awesome,memory:featured.first,pretty:_pretty),
          const SizedBox(height:26),
        ],
        Row(children:[Text('Timeline',style:Theme.of(context).textTheme.titleLarge),const Spacer(),Text('${memories.length} memories',style:Theme.of(context).textTheme.bodySmall)]),
        const SizedBox(height:14),
        if(memories.isEmpty)_Empty(onAdd:()=>_edit()) else for(var i=0;i<memories.length;i++) _TimelineCard(memory:memories[i],last:i==memories.length-1,own:memories[i]['author_id']==_service.userId,pretty:_pretty,onEdit:()=>_edit(memories[i]),onDelete:()=>_delete(memories[i])),
      ]));
    }),
  );
  String _pretty(String raw){final d=DateTime.tryParse(raw);if(d==null)return raw;const months=['','January','February','March','April','May','June','July','August','September','October','November','December'];return '${d.day} ${months[d.month]} ${d.year}';}
}

class _Spotlight extends StatelessWidget{
  const _Spotlight({required this.title,required this.icon,required this.memory,required this.pretty});
  final String title;final IconData icon;final Map<String,dynamic> memory;final String Function(String) pretty;
  @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFFFFEFF3),Color(0xFFFFF8EF)]),borderRadius:BorderRadius.circular(28)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Icon(icon,color:const Color(0xFF9D2443)),const SizedBox(width:8),Text(title,style:const TextStyle(fontWeight:FontWeight.w700,color:Color(0xFF9D2443)))]),const SizedBox(height:14),
    Text(memory['title']?.toString()??'',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:7),
    Text(memory['body']?.toString()??'',maxLines:3,overflow:TextOverflow.ellipsis),const SizedBox(height:12),
    Text(pretty(memory['memory_date']?.toString()??''),style:Theme.of(context).textTheme.bodySmall),
  ]));
}

class _TimelineCard extends StatelessWidget{
  const _TimelineCard({required this.memory,required this.last,required this.own,required this.pretty,required this.onEdit,required this.onDelete});
  final Map<String,dynamic> memory;final bool last,own;final String Function(String) pretty;final VoidCallback onEdit,onDelete;
  @override Widget build(BuildContext context)=>IntrinsicHeight(child:Row(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    SizedBox(width:34,child:Column(children:[Container(width:14,height:14,decoration:const BoxDecoration(shape:BoxShape.circle,color:Color(0xFF9D2443))),if(!last)Expanded(child:Container(width:2,color:const Color(0xFFE8DADD)))])),
    Expanded(child:Padding(padding:const EdgeInsets.only(left:8,bottom:18),child:Container(padding:const EdgeInsets.all(19),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:const Color(0xFFF0E5E7)),borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Text(memory['title']?.toString()??'',style:Theme.of(context).textTheme.titleLarge)),if(memory['is_featured']==true)const Padding(padding:EdgeInsets.only(right:4),child:Icon(Icons.auto_awesome,size:19,color:Color(0xFF9D2443))),if(own)PopupMenuButton<String>(onSelected:(v)=>v=='edit'?onEdit():onDelete(),itemBuilder:(_)=>const[PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:'delete',child:Text('Delete'))])]),
      const SizedBox(height:5),Text(pretty(memory['memory_date']?.toString()??''),style:const TextStyle(fontWeight:FontWeight.w600,color:Color(0xFF9D2443))),
      if((memory['location_label']?.toString()??'').isNotEmpty)...[const SizedBox(height:5),Row(children:[const Icon(Icons.place_outlined,size:16),const SizedBox(width:4),Expanded(child:Text(memory['location_label'].toString(),style:Theme.of(context).textTheme.bodySmall))])],
      const SizedBox(height:12),Text(memory['body']?.toString()??'',style:Theme.of(context).textTheme.bodyLarge),
    ])))),
  ]));
}

class _Empty extends StatelessWidget{const _Empty({required this.onAdd});final VoidCallback onAdd;@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:70),child:Column(children:[const Icon(Icons.collections_bookmark_outlined,size:58,color:Color(0xFFD995A5)),const SizedBox(height:16),Text('Your story starts here',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:7),const Text('Save a date, a place and the story you want to remember.',textAlign:TextAlign.center),const SizedBox(height:18),OutlinedButton.icon(onPressed:onAdd,icon:const Icon(Icons.add),label:const Text('Add first memory'))]));}

class _Editor extends StatefulWidget{const _Editor({required this.service,required this.roomId,this.memory});final MemoryService service;final String roomId;final Map<String,dynamic>? memory;@override State<_Editor> createState()=>_EditorState();}
class _EditorState extends State<_Editor>{
  late final TextEditingController title,body,location;late DateTime date;late bool featured;bool busy=false;
  @override void initState(){super.initState();title=TextEditingController(text:widget.memory?['title']?.toString()??'');body=TextEditingController(text:widget.memory?['body']?.toString()??'');location=TextEditingController(text:widget.memory?['location_label']?.toString()??'');date=DateTime.tryParse(widget.memory?['memory_date']?.toString()??'')??DateTime.now();featured=widget.memory?['is_featured']==true;}
  @override void dispose(){title.dispose();body.dispose();location.dispose();super.dispose();}
  Future<void> save()async{
    if(title.text.trim().isEmpty||body.text.trim().isEmpty)return;setState(()=>busy=true);
    try{
      if(widget.memory==null){await widget.service.create(roomId:widget.roomId,title:title.text.trim(),body:body.text.trim(),date:date,locationLabel:location.text,featured:featured);}
      else{await widget.service.update(id:widget.memory!['id'].toString(),title:title.text.trim(),body:body.text.trim(),date:date,locationLabel:location.text,featured:featured);}
      if(mounted)Navigator.pop(context,true);
    }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not save that memory.')));}finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>Padding(padding:EdgeInsets.only(left:24,right:24,top:18,bottom:MediaQuery.viewInsetsOf(context).bottom+24),child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text(widget.memory==null?'New memory':'Edit memory',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:20),
    TextField(controller:title,maxLength:120,decoration:const InputDecoration(labelText:'Title',prefixIcon:Icon(Icons.favorite_outline))),const SizedBox(height:8),
    TextField(controller:body,maxLength:5000,minLines:4,maxLines:8,decoration:const InputDecoration(labelText:'Tell the story…',alignLabelWithHint:true)),const SizedBox(height:8),
    TextField(controller:location,maxLength:120,decoration:const InputDecoration(labelText:'Place (optional)',prefixIcon:Icon(Icons.place_outlined))),
    ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.calendar_today_outlined),title:const Text('Memory date'),subtitle:Text('${date.day}/${date.month}/${date.year}'),onTap:()async{final x=await showDatePicker(context:context,firstDate:DateTime(2000),lastDate:DateTime.now(),initialDate:date);if(x!=null)setState(()=>date=x);}),
    SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Feature this memory'),subtitle:const Text('Show it at the top of Memories.'),value:featured,onChanged:(v)=>setState(()=>featured=v)),
    const SizedBox(height:12),FilledButton.icon(onPressed:busy?null:save,icon:const Icon(Icons.bookmark_add_outlined),label:Text(busy?'Saving…':'Save memory')),
  ])));
}
