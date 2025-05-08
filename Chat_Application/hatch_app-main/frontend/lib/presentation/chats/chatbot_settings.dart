import 'package:flutter/material.dart';
import 'package:frontend/theme/app_colors.dart';

class ChatbotSettingsScreen extends StatelessWidget {
  final VoidCallback onClearChat;

  const ChatbotSettingsScreen({
    super.key,
    required this.onClearChat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.bottomSheetBgColor,
        title: Text(
          'Chatbot Settings',
          style: TextStyle(color: AppColors.textColor),
        ),
        iconTheme: IconThemeData(color: AppColors.textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Personalisation", style: TextStyle(color: AppColors.lightTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          /* SwitchListTile(
            value: true,
            onChanged: (val) {},
            title: Text("Enable context memory",
                style: TextStyle(color: AppColors.textColor)),
            subtitle: Text("The bot will remember previous messages temporarily",
                style: TextStyle(color: AppColors.lighterTextColor)),
            activeColor: AppColors.primaryColor,
          ),
          const Divider(height: 32), */
          ListTile(
            title: Text("Clear chat history", style: TextStyle(color: AppColors.errorColor)),
            onTap: () {
              onClearChat();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared.')),
              );
            },
          ),
        ],
      ),
    );
  }
}
