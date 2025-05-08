import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/users.dart';
import 'package:frontend/presentation/users.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/presentation/settings/change_password.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  String _profilePictureUrl = "";

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameController.text = user.name;
    _phoneController.text = user.phoneNumber;
    _statusController.text = user.status;
  }

  void _toggleMenu() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    try {
      final user = auth.FirebaseAuth.instance.currentUser;
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

  Future<void> _handleLogout() async {
    try {
      await auth.FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error logging out')),
      );
    }
  }

  Future<void> _updateUserField(String field, String value) async {
    final uid = auth.FirebaseAuth.instance.currentUser!.uid;
    final url = '${dotenv.env['base_url']}/api/user/$uid/update/';

    try {
      final response = await http.patch(
        Uri.parse(url),
        body: json.encode({'field': field, 'value': value}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await ref.read(userProvider.notifier).fetchUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully updated $field')),
        );
      } else {
        throw Exception('Failed to update $field');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating $field: $e')),
      );
    }
  }

  Future<void> _updateProfilePicture() async {
    try {
      final imagePicker = ImagePicker();
      final result = await imagePicker.pickImage(source: ImageSource.gallery);

      if (result == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading image...')),
        );
      }

      final bytes = await result.readAsBytes();
      final fileName = result.name;

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
          _profilePictureUrl = jsonResponse['file_url'];
        });

        await _updateUserField('profile_picture', _profilePictureUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully')),
          );
        }
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: $e')),
        );
      }
    }
  }

  void _showEditDialog(String title, String field, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundColor,
        title: Text(title, style: TextStyle(color: AppColors.textColor)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: AppColors.textColor),
          decoration: InputDecoration(
            hintText: 'Enter new $field',
            hintStyle: TextStyle(color: AppColors.lightTextColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.primaryColor)),
          ),
          TextButton(
            onPressed: () {
              _updateUserField(field, controller.text);
              Navigator.pop(context);
            },
            child: Text('Save', style: TextStyle(color: AppColors.primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User user = ref.watch(userProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        automaticallyImplyLeading: false,
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: AppColors.textColor),
            onPressed: _toggleMenu,
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: AppColors.backgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primaryColor),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            /* ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Security'),
              onTap: () {},
            ), */
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            /* ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Delete My Account'),
              onTap: () {},
            ), */
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: _updateProfilePicture,
              child: Stack(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.bottomSheetBgColor,
                      border: Border.all(color: AppColors.primaryColor),
                      image: DecorationImage(
                        image: NetworkImage(user.profilePicture),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.photo,
                        size: 16,
                        color: AppColors.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showEditDialog('Edit Name', 'name', _nameController),
            child: Text(
              user.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showEditDialog('Edit Status', 'status', _statusController),
                  child: _buildInfoTile(
                    Icons.update,
                    'Status',
                    user.status,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: AppColors.primaryColor),
                onPressed: () => _showEditDialog('Edit Status', 'status', _statusController),
              ),
            ],
          ),
          Divider(color: AppColors.lightTextColor, thickness: 0.3),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showEditDialog('Edit Phone Number', 'phone_number', _phoneController),
                  child: _buildInfoTile(
                    Icons.phone,
                    'Phone Number',
                    user.phoneNumber,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: AppColors.primaryColor),
                onPressed: () => _showEditDialog('Edit Phone Number', 'phone_number', _phoneController),
              ),
            ],
          ),
          Divider(color: AppColors.lightTextColor, thickness: 0.3),
          _buildInfoTile(
            Icons.email_outlined,
            'Email',
            user.email,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppColors.textColor)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 16, color: AppColors.textColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
