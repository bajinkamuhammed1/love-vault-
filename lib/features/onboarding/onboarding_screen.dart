import 'package:flutter/material.dart';
import '../../services/room_service.dart';

class OnboardingScreen extends StatefulWidget {
 const OnboardingScreen({super.key,required this.roomService,required this.onConnected});
 final RoomService roomService;
 final VoidCallback onConnected;
 @override State<OnboardingScreen> createState()=>_OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
 final _name=TextEditingController();
 bool _busy=false;
 String? _error;
 @override void dispose(){_name.dispose();super.dispose();}

 Future<void> _join() async {
  if(_name.text.trim().isEmpty){setState(()=>_error='Enter the name your partner should see.');return;}
  setState((){_busy=true;_error=null;});
  try{
   await widget.roomService.joinVault(_name.text);
   widget.onConnected();
  }catch(e){
   final x=e.toString().toLowerCase();
   if(mounted)setState(()=>_error=x.contains('not approved')?'This email is not approved for this Love Vault.':x.contains('confirm')?'Confirm your email before entering the vault.':'Could not enter Love Vault. Please try again.');
  }finally{if(mounted)setState(()=>_busy=false);}
 }

 @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(
  padding:const EdgeInsets.all(26),
  child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   const Center(child:CircleAvatar(radius:34,backgroundColor:Color(0xFFE9365A),child:Icon(Icons.favorite,color:Colors.white,size:34))),
   const SizedBox(height:20),
   Text('Enter Love Vault',textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineLarge),
   const SizedBox(height:8),
   Text('Your confirmed email must be one of the two approved accounts.',textAlign:TextAlign.center,style:Theme.of(context).textTheme.bodyLarge),
   const SizedBox(height:28),
   TextField(controller:_name,maxLength:50,decoration:const InputDecoration(labelText:'Your display name',prefixIcon:Icon(Icons.person_outline))),
   if(_error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(_error!,textAlign:TextAlign.center,style:TextStyle(color:Theme.of(context).colorScheme.error))),
   const SizedBox(height:18),
   FilledButton.icon(onPressed:_busy?null:_join,icon:const Icon(Icons.lock_open_outlined),label:Text(_busy?'Checking…':'Enter our Love Vault')),
   const SizedBox(height:16),
   const Text('There is only one vault and only the two approved accounts can join it.',textAlign:TextAlign.center,style:TextStyle(fontFamily:'sans-serif',color:Color(0xFF777174))),
  ])),
 ))));
}
