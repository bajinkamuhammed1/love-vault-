import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/room_service.dart';
class ProfileScreen extends StatefulWidget{const ProfileScreen({super.key});@override State<ProfileScreen> createState()=>_ProfileScreenState();}
class _ProfileScreenState extends State<ProfileScreen>{
 late final RoomService _rooms;final _name=TextEditingController();bool _loading=true,_saving=false;
 @override void initState(){super.initState();_rooms=RoomService(Supabase.instance.client);_load();}
 Future<void> _load()async{final p=await _rooms.myProfile();if(!mounted)return;_name.text=p['display_name']?.toString()??'';setState(()=>_loading=false);}
 Future<void> _save()async{if(_name.text.trim().isEmpty)return;setState(()=>_saving=true);try{await _rooms.updateDisplayName(_name.text);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Profile updated')));}finally{if(mounted)setState(()=>_saving=false);}}
 @override void dispose(){_name.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Profile')),body:_loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(24),children:[const CircleAvatar(radius:38,child:Icon(Icons.person_outline,size:42)),const SizedBox(height:24),TextField(controller:_name,maxLength:50,decoration:const InputDecoration(labelText:'Display name',border:OutlineInputBorder())),const SizedBox(height:12),FilledButton.icon(onPressed:_saving?null:_save,icon:const Icon(Icons.save_outlined),label:Text(_saving?'Saving…':'Save profile')),const SizedBox(height:24),const Card(child:ListTile(leading:Icon(Icons.lock_outline),title:Text('Private profile'),subtitle:Text('Your display name is shared only inside your Love Vault room.')))]));
}