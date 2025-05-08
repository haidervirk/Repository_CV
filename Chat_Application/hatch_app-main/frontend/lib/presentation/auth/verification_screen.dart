import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/presentation/navbar.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _canResendEmail = true;
  int _timeLeft = 0;
  Timer? _timer;

  void _startTimer() {
    setState(() {
      _canResendEmail = false;
      _timeLeft = 60; // 60 second cooldown
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _canResendEmail = true;
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _checkEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const NavBar()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email not verified yet. Please check your email.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Text(
            'Logout',
            style: TextStyle(
              color: AppColors.errorColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            FirebaseAuth.instance.signOut();
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Verification',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please check your email for a verification link.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.lightTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationButton() {
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
        onPressed: _checkEmailVerification,
        child: const Text(
          'I\'ve Verified My Email',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildResendEmail() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Didn\'t receive code? ',
          style: TextStyle(color: AppColors.lightTextColor),
        ),
        GestureDetector(
          onTap: _canResendEmail
              ? () {
                  FirebaseAuth.instance.currentUser?.sendEmailVerification();
                  _startTimer();
                }
              : null,
          child: Text(
            _canResendEmail ? 'Resend Email' : 'Wait $_timeLeft seconds',
            style: TextStyle(
              color: _canResendEmail ? AppColors.primaryColor : AppColors.lightTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildVerificationButton(),
              const Spacer(),
              _buildResendEmail(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
