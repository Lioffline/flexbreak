import 'package:flexbreak/pages/variable.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/usersQuotaPage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  final prefs = await SharedPreferences.getInstance();
  LoggeduserID = prefs.getString('loggeduserID') ?? '';
  Profession = prefs.getString('Profession') ?? '';
  userID = LoggeduserID;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),

      home: LoggeduserID.isNotEmpty
          ? (Profession == "Модератор" ? UsersQuotaPage() : HomePage())
          : LoginPage(),

      locale: Locale('ru', 'RU'), 
      supportedLocales: [
        Locale('ru', 'RU'), 
      ],
      
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}