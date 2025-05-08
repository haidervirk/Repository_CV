import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'pages/splash.dart';

final Map<String, List>  data_oosc = {};

void main(){
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "PMIU app",
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3498DB),
          brightness: Brightness.dark// a nice blue color
        ),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 10,
          )
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E4053), // a deep blue-gray color
          titleTextStyle: TextStyle(fontSize: 24,
              fontWeight: FontWeight.bold),
        ),
        scaffoldBackgroundColor: const Color(0xFF1F1F1F), // a dark gray color
      ),
      home: const Splash(),
      //change back to splash
    );
  }
}


