import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/models/chat_item.dart';
import 'package:frontend/models/message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets.dart';
import 'package:frontend/presentation/chats/channel_details.dart';

class ChatScreen extends StatefulWidget {
  final ChatItem chatItem;
  const ChatScreen({super.key, required this.chatItem});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _messageFileUrl = "";
  bool _showScrollToBottom = false;

  List<ChatMessage> _messages = [];
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;
  // ignore: unused_field
  bool _isLoading = false;
  String? _error;

  late StreamSubscription<QuerySnapshot> _messageSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, String>> _getAuthHeaders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'uid': user?.uid ?? '',
      };
    } catch (e) {
      throw Exception('Failed to get auth headers: $e');
    }
  }

  Future<String> _pickAndUploadFile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final choice = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: const Text('Choose upload type'),
              children: <Widget>[
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'file'),
                  child: const Text('File'),
                ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, 'image'),
                  child: const Text('Image'),
                ),
              ],
            );
          });

      if (choice == null) {
        setState(() => _isLoading = false);
        return '';
      }

      late final dynamic result;
      if (choice == 'file') {
        result = await FilePicker.platform.pickFiles();
        if (result == null) {
          setState(() => _isLoading = false);
          return '';
        }
      } else {
        final imagePicker = ImagePicker();
        result = await imagePicker.pickImage(source: ImageSource.gallery);
        if (result == null) {
          setState(() => _isLoading = false);
          return '';
        }
      }

      late final String fileName;
      late final Uint8List bytes;

      if (choice == 'file') {
        fileName = result.files.first.name;
        bytes = result.files.first.bytes!;
      } else {
        fileName = result.name;
        bytes = await result.readAsBytes();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading file...')),
        );
      }

      // Create multipart request
      var uri = Uri.parse('https://api.theuniapp.com/api/upload_file_temp/hatch_123/');
      var request = http.MultipartRequest('POST', uri);

      // Add auth headers
      final headers = await _getAuthHeaders();
      request.headers.addAll(headers);

      // Add file to request
      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          _messageFileUrl = jsonResponse['file_url'];
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File uploaded successfully')),
          );
        }
        return _messageFileUrl;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error picking/uploading file, please try again';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: ${e.toString()}')),
        );
      }
    }
    return '';
  }

  Future<void> _reactToMessage(String messageId) async {
    if (FirebaseAuth.instance.currentUser?.uid == _messages.firstWhere((message) => message.id == messageId).senderId) {
      return;
    }
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await _firestore.collection('channels').doc(widget.chatItem.channelId.toString()).collection('messages').doc(messageId).update({'reaction': '❤️'});

      await http.post(
        Uri.parse('${dotenv.env['base_url']}/api/chat/direct-messages/$messageId/react/'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'reaction': '❤️',
          'channel_id': widget.chatItem.channelId,
        }),
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Error reacting to message, please try again';
        _isLoading = false;
      });
      debugPrint('Error reacting to message: $e');
    }
  }

  Future<void> _joinChannel(String code) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await http.post(
        Uri.parse('${dotenv.env['base_url']}/api/chat/channels/invite/'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined bucket')),
        );
      } else {
        final error = jsonDecode(response.body)['error'];
        throw Exception(error ?? 'Failed to join bucket');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Error joining bucket, please try again';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error ?? 'Failed to join bucket')),
      );
    }
  }

  void _setupFirestoreListener() {
    try {
      _messageSubscription = _firestore.collection('channels').doc(widget.chatItem.channelId.toString()).collection('messages').orderBy('time', descending: true).limit(20).snapshots().listen((snapshot) {
        if (snapshot.docs.isEmpty) return;

        final List<ChatMessage> newMessages = snapshot.docs.map((doc) {
          final data = doc.data();
          final user = FirebaseAuth.instance.currentUser;
          return ChatMessage(
            id: doc.id,
            senderName: data['sender_name'],
            senderEmail: data['sender_email'],
            senderId: data['sender_id'],
            text: data['message_text'],
            time: data['time'],
            channelId: widget.chatItem.channelId.toString(),
            isUser: data['sender_id'] == user?.uid,
            status: data['status'] ?? 'sent',
            reaction: data['reaction'],
            joinChannel: data['join_channel'],
            messageFile: data['message_file'],
          );
        }).toList();

        setState(() {
          _messages = newMessages;
          if (_isAtBottom()) {
            _scrollToBottom();
          } else {
            _showScrollToBottom = true;
          }
        });
      }, onError: (e) {
        setState(() => _error = 'Error listening to messages, please try again');
      });
    } catch (e) {
      setState(() => _error = 'Error setting up message listener, please try again');
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;

    try {
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });

      final lastMessage = _messages.last;
      final snapshot = await _firestore.collection('channels').doc(widget.chatItem.channelId.toString()).collection('messages').orderBy('time', descending: true).startAfter([lastMessage.time]).limit(20).get();

      if (mounted) {
        setState(() {
          final moreMessages = snapshot.docs.map((doc) {
            final data = doc.data();
            final user = FirebaseAuth.instance.currentUser;
            return ChatMessage(
              id: doc.id,
              senderName: data['sender_name'],
              senderEmail: data['sender_email'],
              senderId: data['sender_id'],
              text: data['message_text'],
              time: data['time'],
              channelId: widget.chatItem.channelId.toString(),
              isUser: data['sender_id'] == user?.uid,
              status: data['status'] ?? 'sent',
              reaction: data['reaction'],
              joinChannel: data['join_channel'],
              messageFile: data['message_file'],
            );
          }).toList();

          _messages.addAll(moreMessages);
          _isLoadingMore = false;
          _hasMoreMessages = moreMessages.length == 20;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading more messages, please try again';
        _isLoadingMore = false;
      });
    }
  }

  bool _isAtBottom() {
    if (!_scrollController.hasClients) return true;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 50);
  }

  @override
  void initState() {
    super.initState();
    _setupFirestoreListener();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels <= _scrollController.position.minScrollExtent) {
        _loadMoreMessages();
      }
      setState(() {
        _showScrollToBottom = !_isAtBottom();
      });
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _messageFileUrl.isEmpty) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _controller.clear();
      final user = FirebaseAuth.instance.currentUser;
      final now = DateTime.now().toIso8601String();

      final messageData = {
        'sender_name': user?.displayName ?? '',
        'sender_email': user?.email ?? '',
        'sender_id': user?.uid ?? '',
        'message_text': text,
        'message_file': _messageFileUrl,
        'time': now,
        'channel_id': widget.chatItem.channelId,
        'status': 'sending',
      };

      final docRef = await _firestore.collection('channels').doc(widget.chatItem.channelId.toString()).collection('messages').add(messageData);

      await docRef.update({'status': 'sent'});

      await http.post(
        Uri.parse('${dotenv.env['base_url']}/api/chat/direct-messages/${widget.chatItem.channelId}/send/'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'message_text': text,
          'message_file': _messageFileUrl,
          'channel_id': widget.chatItem.channelId,
        }),
      );

      setState(() {
        _messageFileUrl = "";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error sending message, please try again';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error ?? 'Failed to send message')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      setState(() => _showScrollToBottom = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _messageSubscription.cancel();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
        backgroundColor: const Color(0xFF1f2c34),
        elevation: 0,
        toolbarHeight: 70,
        leadingWidth: 25,
        automaticallyImplyLeading: false,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChannelDetailsScreen(
                  channelId: widget.chatItem.channelId,
                ),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(widget.chatItem.profilePicture),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.chatItem.channelName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
              ),
            ],
          ),
        ));
  }

  Widget _buildErrorScreen() {
    return ErrorScreen(
      emoji: '😕',
      title: 'Error',
      description: _error!,
      onRetry: () {
        setState(() {
          _error = null;
          _isLoading = true;
        });
        _sendMessage();
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMessageList() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _messages.length,
        reverse: true,
        itemBuilder: (context, index) => GestureDetector(
          onDoubleTap: () => _reactToMessage(_messages[index].id),
          child: Column(
            children: [
              GestureDetector(
                onTap: (_messages[index].messageFile != null && _messages[index].messageFile!.isNotEmpty)
                    ? () async {
                        final url = Uri.parse(_messages[index].messageFile!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      }
                    : null,
                child: ChatBubble(
                  message: _messages[index],
                  onJoinChannel: _messages[index].joinChannel != null ? () => _joinChannel(_messages[index].joinChannel!) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1f2c34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAddFileButton(),
            const SizedBox(width: 8),
            _buildMessageTextField(),
            const SizedBox(width: 8),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFileButton() {
    return IconButton(
      icon: const Icon(Icons.add, color: Colors.white),
      onPressed: _pickAndUploadFile,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildMessageTextField() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_messageFileUrl.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF075E54).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF075E54).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.attach_file,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'File attached',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _messageFileUrl = '';
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'message...',
              hintStyle: TextStyle(color: Colors.grey[800]),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return FloatingActionButton(
      onPressed: _sendMessage,
      mini: true,
      backgroundColor: const Color(0xFF6355d9),
      child: const Icon(Icons.send, size: 20),
    );
  }

  Widget _buildScrollToBottomButton() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: FloatingActionButton(
        onPressed: _scrollToBottom,
        mini: true,
        backgroundColor: Colors.grey[800],
        child: const Icon(Icons.arrow_downward, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF293247),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          if (_error != null) _buildErrorScreen(),
          Column(
            children: [
              if (_isLoadingMore) _buildLoadingIndicator(),
              _buildMessageList(),
              _buildMessageInput(),
            ],
          ),
          if (_showScrollToBottom) _buildScrollToBottomButton(),
        ],
      ),
    );
  }
}
