// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/games_info_provider.dart';
import 'package:flutter_app/providers/users_info_provider.dart';
import 'package:flutter_app/providers/star_users_info_provider.dart';
import 'package:flutter_app/screens/login.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  initializeDateFormatting('ko_KR');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GamesInfoProvider()),
        ChangeNotifierProvider(create: (_) => UsersInfoProvider()),
        ChangeNotifierProvider(create: (_) => StarUsersInfoProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GNU-PingPong-App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}
