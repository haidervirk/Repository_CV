import 'package:flutter/material.dart';

class NotificationSettings extends StatefulWidget {
  @override
  _NotificationSettingsState createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool _allowNotifications = true;
  bool _alerts = true;
  bool _updates = true;
  bool _promotions = true;
  String _notificationFrequency = 'Immediately';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Allow Notifications' , style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),),
              value: _allowNotifications,
              onChanged: (bool value) {
                setState(() {
                  _allowNotifications = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Notification Types:', style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            ),
            SwitchListTile(
              title: const Text('Alerts' , style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),),
              value: _alerts,
              onChanged: (bool value) {
                setState(() {
                  _alerts = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Updates', style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              ),),
              value: _updates,
              onChanged: (bool value) {
                setState(() {
                  _updates = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Promotions' , style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),),
              value: _promotions,
              onChanged: (bool value) {
                setState(() {
                  _promotions = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Notification Frequency:', style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            ),
            DropdownButton<String>(
              value: _notificationFrequency,
              onChanged: (String? value) {
                setState(() {
                  _notificationFrequency = value!;
                });
              },
              items: [
                'Immediately',
                'Daily',
                'Weekly',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}