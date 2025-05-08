import 'package:flutter/material.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/presentation/chats/chatbot_settings.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_markdown/flutter_markdown.dart';

class Message {
  final String sender;
  final String text;

  Message({required this.sender, required this.text});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isThinking = false;
  late AnimationController _thinkingAnimationController;
  final List<String> _thinkingPhrases = ["Processing input...", "Analyzing context...", "Computing response...", "Synthesizing data...", "Generating reply..."];

  @override
  void initState() {
    super.initState();
    _thinkingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _thinkingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(Message(sender: 'user', text: text.trim()));
      _isThinking = true;
    });
    _controller.clear();

    final botReply = await fetchBotReply(text.trim());

    setState(() {
      _messages.add(Message(sender: 'bot', text: botReply));
      _isThinking = false;
    });
  }

  Future<String> fetchBotReply(String userInput) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['base_url']}/api/chat/chatbot/message/'),
        headers: {
          'Content-Type': 'application/json',
          'uid': FirebaseAuth.instance.currentUser!.uid,
        },
        body: json.encode({
          'message': userInput,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['current_message']['bot_reply'];
      } else {
        throw Exception('Failed to get bot reply');
      }
    } catch (e) {
      return "Sorry, I encountered an error processing your message.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.bottomSheetBgColor,
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primaryColor, size: 28),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Sensei", style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.bold)),
                Text("Chatbot", style: TextStyle(color: AppColors.lightestTextColor, fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatbotSettingsScreen(
                    onClearChat: () {
                      setState(() {
                        _messages.clear();
                      });
                    },
                  ),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isThinking && index == _messages.length) {
                  return _buildBotThinking();
                }
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.sender == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.auto_awesome, color: AppColors.primaryColor),
              ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primaryColor : AppColors.bottomSheetBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: !isUser
                      ? Border.all(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: MarkdownBody(
                  data: message.text,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: isUser ? AppColors.textColor : AppColors.secondaryColor,
                    ),
                    code: TextStyle(
                      backgroundColor: Colors.grey[200],
                      color: AppColors.primaryColor,
                      fontFamily: 'monospace',
                    ),
                    blockquote: TextStyle(
                      color: isUser ? AppColors.textColor.withOpacity(0.8) : AppColors.secondaryColor.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                    strong: TextStyle(
                      color: isUser ? AppColors.textColor : AppColors.secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    em: TextStyle(
                      color: isUser ? AppColors.textColor : AppColors.secondaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotThinking() {
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 6, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _thinkingAnimationController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bottomSheetBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.memory,
                      color: AppColors.primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _thinkingPhrases[(_thinkingAnimationController.value * _thinkingPhrases.length).floor() % _thinkingPhrases.length],
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(3, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryColor.withOpacity(
                              math.sin((_thinkingAnimationController.value * 2 * math.pi) + (index * math.pi / 2)).abs(),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    hintText: "message...",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  onSubmitted: _handleSendMessage,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: () => _handleSendMessage(_controller.text),
                iconSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
