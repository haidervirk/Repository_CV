import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateCommunityScreen extends ConsumerStatefulWidget {
  final String? bucketId;
  final String? bucketName;
  const CreateCommunityScreen({super.key, this.bucketId, this.bucketName});

  @override
  CreateCommunityScreenState createState() => CreateCommunityScreenState();
}

class CreateCommunityScreenState extends ConsumerState<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bucketNameController = TextEditingController();
  final _channelNameController = TextEditingController();
  final _emailListController = TextEditingController();
  final _descriptionController = TextEditingController();
  XFile? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.bucketName != null) {
      _bucketNameController.text = widget.bucketName!;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _createCommunity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Now create the community
      final url = Uri.parse('${dotenv.env['base_url']}/api/chat/channels/create/');

      // Parse email list into array
      List<String> emailList = [];
      if (_emailListController.text.isNotEmpty) {
        emailList = _emailListController.text.split(',').map((e) => e.trim()).toList();
      }

      // Prepare request body
      final Map<String, dynamic> body = {'bucket': widget.bucketId ?? '', 'bucket_name': _bucketNameController.text, 'name': _channelNameController.text, 'members': emailList, 'channel_type': 'community'};

      if (_descriptionController.text.isNotEmpty) {
        body['description'] = _descriptionController.text;
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'uid': FirebaseAuth.instance.currentUser!.uid, 'Authorization': 'Bearer ${await FirebaseAuth.instance.currentUser!.getIdToken()}'},
        body: json.encode(body),
      );

      final decodedResponse = json.decode(response.body);

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(decodedResponse['message'] ?? 'Community created successfully')),
          );
        }
      } else {
        throw Exception(decodedResponse['error'] ?? 'An unexpected error occurred');
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _bucketNameController.dispose();
    _channelNameController.dispose();
    _emailListController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.bottomSheetBgColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text('Create'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        hintText: 'Community Name',
                        controller: _bucketNameController,
                        enabled: widget.bucketId == null,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a community name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        hintText: 'Channel Name',
                        controller: _channelNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a channel name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        hintText: 'Email List (comma separated)',
                        controller: _emailListController,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        hintText: 'Description',
                        controller: _descriptionController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: AppColors.textColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isLoading ? null : _createCommunity,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Create Community',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int? maxLines,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines ?? 1,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.bottomSheetBgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.25), width: 0.25),
        ),
      ),
      validator: validator,
    );
  }
}
