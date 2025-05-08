import 'package:flutter/material.dart';

class CardWidget extends StatelessWidget {
  final List<String> toDisplay;
  const CardWidget({super.key, required this.toDisplay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 8),
      child: SizedBox(
        width: 150,
        height: 150,
        child: Card(
          elevation: 10,
          color: const Color(0xFFFFF500),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(toDisplay[0],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),),
              ),
              Card(
                color: const Color(0xFF2E4053),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(toDisplay[1],
                    textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),),
                ),
              ),
            ],
          ), // Add null check
        ),
      ),
    );
  }
}
