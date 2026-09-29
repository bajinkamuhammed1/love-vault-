import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/room_service.dart';
import '../play/play_screen.dart';import '../settings/settings_screen.dart';import '../ask_me/ask_me_screen.dart';import '../surprise/surprise_screen.dart';import '../memories/memories_screen.dart';import '../profile/profile_screen.dart';
class HomeShell extends StatefulWidget{const HomeShell({super.key,required this.room});final Map<String,dynamic> room;@override State<HomeShell> createState()=>_HomeShellState();}
class _HomeShellState extends State<HomeShell>{
 int _index=0;late final RoomService _rooms;late Map<String,dynamic> _room;Timer? _timer;
 static const _titles=['Home','Play','Ask Me','Surprise','Memories'];static const _icons=[Icons.home_outlined,Icons.casino_outlined,Icons.question_answer_outlined,Icons.card_giftcard_outlined,Icons.auto_stories_outlined];
 @override void initState(){super.initState();_room=Map.of(widget.room);_rooms=RoomService(Supabase.instance.client);_refresh();_timer=Timer.periodic(const Duration(seconds:3),(_)=>_refresh());}
 Future<void> _refresh()async{try{final r=await _rooms.roomSnapshot(widget.room['id'].toString());if(mounted)setState(()=>_room=r);}catch(_){}}
 @override void dispose(){_timer?.cancel();super.dispose();}
 @override Widget build(BuildContext context){final code=_room['room_code']?.toString()??'';return Scaffold(
  appBar:AppBar(title:Text(_titles[_index])),drawer:Drawer(child:SafeArea(child:ListView(children:[
   ListTile(leading:const Icon(Icons.favorite_outline),title:const Text('Love Vault'),subtitle:Text('Room $code')),const Divider(),
   ListTile(leading:const Icon(Icons.person_outline),title:const Text('Profile'),onTap:(){Navigator.pop(context);Navigator.push(context,MaterialPageRoute(builder:(_)=>const ProfileScreen())).then((_)=>_refresh());}),
   ListTile(leading:const Icon(Icons.settings_outlined),title:const Text('Settings'),onTap:(){Navigator.pop(context);Navigator.push(context,MaterialPageRoute(builder:(_)=>SettingsScreen(roomId:_room['id'].toString())));})
  ]))),
  body:IndexedStack(index:_index,children:[_HomePage(room:_room),PlayScreen(roomId:_room['id'].toString()),AskMeScreen(roomId:_room['id'].toString()),SurpriseScreen(roomId:_room['id'].toString()),MemoriesScreen(roomId:_room['id'].toString())]),
  bottomNavigationBar:NavigationBar(selectedIndex:_index,onDestinationSelected:(v)=>setState(()=>_index=v),destinations:List.generate(_titles.length,(i)=>NavigationDestination(icon:Icon(_icons[i]),label:_titles[i]))));}
}
class _HomePage extends StatelessWidget{const _HomePage({required this.room});final Map<String,dynamic> room;
 @override Widget build(BuildContext context){final members=(room['members'] as List?)??const[];final connected=members.length>=2;final code=room['room_code']?.toString()??'';
 return RefreshIndicator(onRefresh:()async{},child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.all(24),children:[
  const SizedBox(height:18),Center(child:CircleAvatar(radius:42,child:Icon(connected?Icons.favorite:Icons.hourglass_top,size:44))),const SizedBox(height:16),
  Text(connected?'You’re connected':'Waiting for your partner',style:Theme.of(context).textTheme.headlineMedium,textAlign:TextAlign.center),const SizedBox(height:8),
  Text(connected?'Your private space is ready. Play, ask, surprise and save memories together.':'Share your room code. This page updates automatically when they join.',textAlign:TextAlign.center),
  const SizedBox(height:24),Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[const Text('Your room'),const SizedBox(height:8),SelectableText(code,style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:14),Wrap(alignment:WrapAlignment.center,spacing:12,runSpacing:8,children:[for(final m in members)Chip(avatar:const Icon(Icons.person,size:18),label:Text(m['display_name']?.toString()??'Player')),if(members.length<2)const Chip(avatar:Icon(Icons.hourglass_empty,size:18),label:Text('Waiting…'))])]))),
  const SizedBox(height:14),Card(child:ListTile(leading:const Icon(Icons.casino_outlined),title:const Text('6-question rounds'),subtitle:Text(connected?'Both of you answer the same question before moving on.':'Play unlocks when your partner joins.')))
 ]));}}
