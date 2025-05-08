import 'package:flutter/material.dart';
import 'package:pmiuapp/pages/map_page.dart';
import 'package:pmiuapp/pages/settings.dart';
import 'package:pmiuapp/pages/about_us.dart';

class menu extends StatelessWidget {
  const menu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String result) {
      if (result == 'Option 1') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Map()),
        );
      }
      else if (result == 'Option 2') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotificationSettings()),
        );
      }

      else if (result == 'Option 3') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Info()),
        );
      }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'Option 1',
          child: Text('Use Maps'),
        ),
        const PopupMenuItem<String>(
          value: 'Option 2',
          child: Text('Settings'),
        ),
        const PopupMenuItem<String>(
          value: 'Option 3',
          child: Text('About us'),
        ),
      ],
    );
  }
}
