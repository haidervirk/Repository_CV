import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pmiuapp/pages/first_page.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {

  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 3), (){
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => PageOne()));
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2E4053),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Image.asset('assets/images/splash.png'),
              ),
              const Text("Out Of School \n \t \t  Children",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),),
            ],
          ),
        ),
      ),
    );
  }
}

