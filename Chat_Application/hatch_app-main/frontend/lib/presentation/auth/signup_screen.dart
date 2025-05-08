import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/presentation/auth/login_screen.dart';
import 'package:frontend/presentation/navbar.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  String _username = '';
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  bool _showPassword = false;

  void _setLoading(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const NavBar(),
        ),
        (route) => false,
      );
    }
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  Future<void> _handleAuthError(FirebaseAuthException e) async {
    String message;
    switch (e.code) {
      case 'weak-password':
        message = 'The password provided is too weak';
        break;
      case 'email-already-in-use':
        message = 'An account already exists for that email';
        break;
      case 'invalid-email':
        message = 'The email address is not valid';
        break;
      case 'operation-not-allowed':
        message = 'Email/password accounts are not enabled';
        break;
      case 'network-request-failed':
        message = 'Network error occurred. Please check your connection';
        break;
      default:
        message = 'An error occurred: ${e.message}';
    }
    _showErrorSnackBar(message);
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    _setLoading(true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      await userCredential.user?.updateDisplayName(_username);

      // API call to create user
      await http.post(
        // Uri.parse('${dotenv.env['base_url']}/api/users/'),
        Uri.parse('${dotenv.env['base_url']}/api/user/create/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _email, 'name': _username, 'id': userCredential.user?.uid}),
      );
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      await _handleAuthError(e);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    _setLoading(true);
  }

  Widget _buildTextField({
    required String hintText,
    required Function(String?) validator,
    required Function(String?) onSaved,
    bool obscureText = false,
    bool? showPassword,
    VoidCallback? onTogglePassword,
  }) {
    return TextFormField(
      obscureText: obscureText && (showPassword == null || !showPassword),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.bottomSheetBgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25), width: 0.25),
        ),
        suffixIcon: obscureText
            ? IconButton(
                icon: Icon(
                  showPassword ?? false ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.lightTextColor,
                ),
                onPressed: onTogglePassword,
              )
            : null,
      ),
      validator: (value) => validator(value) as String?,
      onSaved: onSaved,
    );
  }

  Widget _buildDivider() {
    return Expanded(
      child: Divider(
        color: AppColors.lightTextColor.withValues(alpha: 0.25),
        thickness: 0.5,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        const SizedBox(height: 32),
        const Text(
          'Hello! Register to get started',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      children: [
        _buildTextField(
          hintText: 'Username',
          validator: _validateUsername,
          onSaved: (value) => _username = value ?? '',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          hintText: 'Email',
          validator: _validateEmail,
          onSaved: (value) => _email = value ?? '',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          hintText: 'Password',
          validator: _validatePassword,
          onSaved: (value) => _password = value ?? '',
          obscureText: true,
          showPassword: _showPassword,
          onTogglePassword: () => setState(() => _showPassword = !_showPassword),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
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
        onPressed: _isLoading ? null : _signUp,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Register',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textColor,
          side: BorderSide(color: AppColors.lightTextColor.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _isLoading ? null : _signUpWithGoogle,
        child: _isLoading
            ? const CircularProgressIndicator()
            : Image.network(
                'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                height: 48,
                width: 48,
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(color: AppColors.lightTextColor),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          },
          child: Text(
            'Login Now',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        _buildDivider(),
        const SizedBox(width: 16),
        Text(
          'Or Register with',
          style: TextStyle(color: AppColors.lightTextColor),
        ),
        const SizedBox(width: 16),
        _buildDivider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 32),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildRegistrationForm(),
                  const SizedBox(height: 32),
                  _buildRegisterButton(),
                  /* const SizedBox(height: 32),
                  _buildOrDivider(),
                  const SizedBox(height: 32),
                  _buildGoogleSignInButton(),
                   */
                  const Spacer(),
                  _buildLoginLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
