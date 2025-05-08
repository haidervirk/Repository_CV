import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/presentation/auth/verification_screen.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/presentation/chats/all_chats.dart';
import 'package:frontend/presentation/communities/communities.dart';
import 'package:frontend/presentation/communities/community_detail.dart';

import 'package:frontend/presentation/tasks/task_dashboard_screen.dart';
import 'package:frontend/presentation/settings/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NavBar extends ConsumerStatefulWidget {
  const NavBar({super.key});

  @override
  ConsumerState<NavBar> createState() => _NavBarState();
}

class _NavBarState extends ConsumerState<NavBar> {
  int _selectedIndex = 0;
  bool _isEmailVerified = true;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      if (mounted) {
        setState(() {
          _isEmailVerified = user.emailVerified;
          if (!_isEmailVerified) {
            user.sendEmailVerification();
          }
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEmailVerified) {
      return const VerificationScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.bottomSheetBgColor,
        indicatorColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: <Widget>[
          GestureDetector(
            onTap: () => _onItemTapped(0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/icons/chats.svg', color: _selectedIndex == 0 ? AppColors.primaryColor : AppColors.lighterTextColor),
                Text('Chats', style: TextStyle(color: _selectedIndex == 0 ? AppColors.primaryColor : AppColors.lighterTextColor)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _onItemTapped(1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/icons/community.svg', color: _selectedIndex == 1 ? AppColors.primaryColor : AppColors.lighterTextColor),
                Text('Communities', style: TextStyle(color: _selectedIndex == 1 ? AppColors.primaryColor : AppColors.lighterTextColor)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _onItemTapped(2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/icons/tasks.svg', color: _selectedIndex == 2 ? AppColors.primaryColor : AppColors.lighterTextColor),
                Text('Tasks', style: TextStyle(color: _selectedIndex == 2 ? AppColors.primaryColor : AppColors.lighterTextColor)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _onItemTapped(3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/icons/settings.svg', color: _selectedIndex == 3 ? AppColors.primaryColor : AppColors.lighterTextColor),
                Text('Settings', style: TextStyle(color: _selectedIndex == 3 ? AppColors.primaryColor : AppColors.lighterTextColor)),
              ],
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          HatchHomeScreen(),
          CommunitiesScreen(),
          TaskDashboardScreen(),
          SettingsScreen(),
        ],
      ),
    );
  }
}
