import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget{const AuthScreen({super.key});@override State<AuthScreen> createState()=>_AuthScreenState();}
class _AuthScreenState extends State<AuthScreen>{
 final _email=TextEditingController(),_password=TextEditingController(),_code=TextEditingController(),_name=TextEditingController();
 bool _busy=false,_partner=false;String? _message;
 @override void dispose(){_email.dispose();_password.dispose();_code.dispose();_name.dispose();super.dispose();}
 Future<void> _ownerLogin()async{final e=_email.text.trim(),p=_password.text;if(e.isEmpty||p.length<6){setState(()=>_message='Enter your email and password.');return;}setState((){_busy=true;_message=null;});try{await Supabase.instance.client.auth.signInWithPassword(email:e,password:p);}on AuthException catch(e){if(mounted)setState(()=>_message=e.message);}catch(_){if(mounted)setState(()=>_message='Could not sign in. Try again.');}finally{if(mounted)setState(()=>_busy=false);}}
 Future<void> _partnerLogin()async{final c=_code.text.trim();if(c.isEmpty){setState(()=>_message='Enter the code from your partner.');return;}setState((){_busy=true;_message=null;});try{final auth=Supabase.instance.client.auth;await auth.signInAnonymously();try{await Supabase.instance.client.rpc('redeem_pairing_code',params:{'p_code':c,'p_display_name':_name.text.trim().isEmpty?'Partner':_name.text.trim()});}catch(e){await auth.signOut();rethrow;}}on AuthException catch(e){if(mounted)setState(()=>_message=e.message);}catch(e){if(mounted)setState(()=>_message=e.toString().toLowerCase().contains('expired')?'That code is invalid or expired. Ask your partner for a new code.':'Could not connect with that code. Try again.');}finally{if(mounted)setState(()=>_busy=false);}}
 @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(26),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:430),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 const Center(child:CircleAvatar(radius:34,backgroundColor:Color(0xFFE9365A),child:Icon(Icons.favorite,color:Colors.white,size:34))),const SizedBox(height:18),Text('Love Vault',textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineLarge),const SizedBox(height:8),const Text('One private space for the two of you.',textAlign:TextAlign.center),const SizedBox(height:24),
 Container(padding:const EdgeInsets.all(5),decoration:BoxDecoration(color:const Color(0xFFFFF1F4),borderRadius:BorderRadius.circular(20)),child:SegmentedButton<bool>(segments:const[ButtonSegment(value:true,icon:Icon(Icons.favorite_outline),label:Text('Partner code')),ButtonSegment(value:false,icon:Icon(Icons.lock_outline),label:Text('Owner login'))],selected:{_partner},onSelectionChanged:_busy?null:(v)=>setState((){_partner=v.first;_message=null;}))),const SizedBox(height:22),
 if(_partner)...[
 Text('Join your partner',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:6),const Text('Enter the one-time pairing or recovery code your partner generated for you.'),const SizedBox(height:16),
 TextField(controller:_name,maxLength:50,decoration:const InputDecoration(labelText:'Your name',prefixIcon:Icon(Icons.person_outline))),const SizedBox(height:10),
 TextField(controller:_code,autocorrect:false,textCapitalization:TextCapitalization.characters,decoration:const InputDecoration(labelText:'Pairing or recovery code',prefixIcon:Icon(Icons.key_outlined))),const SizedBox(height:18),
 FilledButton.icon(onPressed:_busy?null:_partnerLogin,icon:const Icon(Icons.lock_open_outlined),label:Text(_busy?'Checking code…':'Enter Love Vault')),
 ]else...[
 Text('Owner login',style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:6),const Text('Use your existing Love Vault email and password.'),const SizedBox(height:16),
 TextField(controller:_email,keyboardType:TextInputType.emailAddress,autofillHints:const[AutofillHints.email],decoration:const InputDecoration(labelText:'Email',prefixIcon:Icon(Icons.email_outlined))),const SizedBox(height:12),
 TextField(controller:_password,obscureText:true,autofillHints:const[AutofillHints.password],onSubmitted:(_)=>_busy?null:_ownerLogin(),decoration:const InputDecoration(labelText:'Password',prefixIcon:Icon(Icons.lock_outline))),const SizedBox(height:18),
 FilledButton(onPressed:_busy?null:_ownerLogin,child:Text(_busy?'Signing in…':'Sign in')),
 ],
 if(_message!=null)Padding(padding:const EdgeInsets.only(top:14),child:Text(_message!,textAlign:TextAlign.center,style:TextStyle(color:Theme.of(context).colorScheme.error))),
 const SizedBox(height:16),const Text('Partner codes work once and expire after 30 minutes.',textAlign:TextAlign.center,style:TextStyle(fontFamily:'sans-serif',color:Color(0xFF777174))),
]))))));
}
