// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/games_info_provider.dart';
import 'package:flutter_app/providers/users_info_provider.dart';
import 'package:flutter_app/providers/star_users_info_provider.dart';
import 'package:flutter_app/screens/login.dart';
import 'package:flutter_app/screens/post_create.dart';
import 'package:flutter_app/screens/home.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() async {
  // Flutter 엔진이 위젯을 바인딩하기 전에 플러그인 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();

  // 블루투스 플러그인 초기화
  await FlutterBluetoothSerial.instance;

  initializeDateFormatting('ko_KR');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GamesInfoProvider()),
        ChangeNotifierProvider(create: (context) => UsersInfoProvider()),
        ChangeNotifierProvider(create: (context) => StarUsersInfoProvider()),
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
      routes: {
        '/home': (context) => const HomePage(),
        '/post_create': (context) => const RecruitPostPage(),
      },
    );
  }
}
