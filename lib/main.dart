import 'package:flutter/material.dart';
import 'package:flutter_application_2/folder/browse.dart';
import 'package:flutter_application_2/folder/first_page.dart';
import 'package:flutter_application_2/folder/stream.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black87,
        primaryColor: Colors.orange,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black87),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black87,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: FirstPage(),
      routes: {
        '/firstpage': (context) => FirstPage(),
        '/browsepage': (context) => Browse(),
        '/streampage': (context) => StreamPage(),
      },
    );
  }
}
