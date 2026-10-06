import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'services/room_service.dart';

class LoveVaultApp extends StatelessWidget {
 const LoveVaultApp({super.key});
 @override Widget build(BuildContext context){
  const rose=Color(0xFFE9365A), ink=Color(0xFF201D1E), blush=Color(0xFFFFF3F5);
  final scheme=ColorScheme.fromSeed(seedColor:rose,brightness:Brightness.light,surface:Colors.white);
  return MaterialApp(debugShowCheckedModeBanner:false,title:'Love Vault',theme:ThemeData(
   useMaterial3:true,colorScheme:scheme,scaffoldBackgroundColor:Colors.white,fontFamily:'serif',
   textTheme:const TextTheme(headlineLarge:TextStyle(fontSize:36,fontWeight:FontWeight.w700,color:ink,height:1.08),headlineMedium:TextStyle(fontSize:30,fontWeight:FontWeight.w700,color:ink,height:1.12),headlineSmall:TextStyle(fontSize:24,fontWeight:FontWeight.w700,color:ink),titleLarge:TextStyle(fontSize:20,fontWeight:FontWeight.w700,color:ink),bodyLarge:TextStyle(fontFamily:'sans-serif',fontSize:17,height:1.45,color:Color(0xFF655F62)),bodyMedium:TextStyle(fontFamily:'sans-serif',fontSize:15,height:1.4,color:Color(0xFF777174)),labelLarge:TextStyle(fontFamily:'sans-serif',fontWeight:FontWeight.w600)),
   cardTheme:CardThemeData(color:Colors.white,elevation:0,margin:EdgeInsets.zero,shape:RoundedRectangleBorder(borderRadius:BorderRadius.all(Radius.circular(22)),side:BorderSide(color:Color(0xFFF0E5E8)))),
   filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(backgroundColor:rose,foregroundColor:Colors.white,padding:const EdgeInsets.symmetric(horizontal:22,vertical:16),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22)),textStyle:const TextStyle(fontFamily:'sans-serif',fontSize:16,fontWeight:FontWeight.w600))),
   inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:const BorderSide(color:Color(0xFFECE3E6))),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:const BorderSide(color:Color(0xFFECE3E6))),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:const BorderSide(color:rose,width:1.5))),
   navigationBarTheme:NavigationBarThemeData(height:72,backgroundColor:Colors.white,indicatorColor:blush,labelTextStyle:WidgetStateProperty.resolveWith((s)=>TextStyle(fontFamily:'sans-serif',fontSize:12,fontWeight:s.contains(WidgetState.selected)?FontWeight.w600:FontWeight.w400,color:s.contains(WidgetState.selected)?rose:const Color(0xFF8A8587))),iconTheme:WidgetStateProperty.resolveWith((s)=>IconThemeData(color:s.contains(WidgetState.selected)?rose:const Color(0xFF8A8587)))),
  ),home:const _AuthGate());
 }
}

class _AuthGate extends StatefulWidget { const _AuthGate(); @override State<_AuthGate> createState()=>_AuthGateState(); }
class _AuthGateState extends State<_AuthGate> {
 late final Stream<AuthState> _changes;
 @override void initState(){super.initState();_changes=Supabase.instance.client.auth.onAuthStateChange;}
 @override Widget build(BuildContext context)=>StreamBuilder<AuthState>(
  stream:_changes,
  builder:(context,_) {
   if(Supabase.instance.client.auth.currentSession==null) return const AuthScreen();
   return const _AppGate();
  },
 );
}

class _AppGate extends StatefulWidget{const _AppGate();@override State<_AppGate> createState()=>_AppGateState();}
class _AppGateState extends State<_AppGate>{late final RoomService _rooms;late Future<Map<String,dynamic>?> _roomFuture;@override void initState(){super.initState();_rooms=RoomService(Supabase.instance.client);_reload();}void _reload(){_roomFuture=_rooms.currentRoom();}
 @override Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>?>(future:_roomFuture,builder:(context,s){if(s.connectionState!=ConnectionState.done)return const Scaffold(body:Center(child:CircularProgressIndicator()));if(s.hasError)return Scaffold(body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Text('Could not load Love Vault: ${s.error}'))));final room=s.data;if(room!=null)return HomeShell(room:room);return OnboardingScreen(roomService:_rooms,onConnected:()=>setState(_reload));});}
