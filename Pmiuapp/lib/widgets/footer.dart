import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0,12,0,0),
      child: Container(
        color: const Color(0xFF2E4053),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(0,10,0,0),
                  child: Text(
                    'Contact Us:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text('Email: info@pesrp.edu.pk'),
                Padding(
                  padding: EdgeInsets.fromLTRB(0,0,0,10),
                  child: Text('Phone: +92 (42) 99260125'),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Follow Us:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(Icons.facebook),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
