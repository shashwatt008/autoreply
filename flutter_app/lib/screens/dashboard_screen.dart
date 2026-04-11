import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/platform_card.dart';
import '../widgets/upgrade_banner.dart';
import '../widgets/loading_widget.dart';
import 'login_screen.dart';
import 'platform_screen.dart';
import 'upgrade_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? _user;
  bool _isLoading = true;
  bool _hasError = false;
  int _fbRulesCount = 0;
  int _igRulesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final user = await ApiService.getMe();
      if (user == null) {
        // Token invalid, go back to login
        await AuthService.removeToken();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
        return;
      }

      await AuthService.saveUserInfo(user.name, user.profilePic);

      // Fetch rule counts per platform
      final fbRules = await ApiService.getRuleCount(platform: 'facebook');
      final igRules = await ApiService.getRuleCount(platform: 'instagram');

      if (mounted) {
        setState(() {
          _user = user;
          _fbRulesCount = fbRules;
          _igRulesCount = igRules;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: AppConstants.errorRed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.removeToken();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: LoadingWidget(message: 'Loading your dashboard...'),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: ErrorRetryWidget(
          message: 'Failed to load dashboard. Please check your connection.',
          onRetry: _loadData,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          AppConstants.appName,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppConstants.primaryColor,
          ),
        ),
        actions: [
          if (_user?.profilePic != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(_user!.profilePic!),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppConstants.textSecondary),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppConstants.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${_user?.name.split(' ').first ?? 'there'}!',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your auto-reply automations',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_user?.isPro ?? false)
                          ? AppConstants.primaryColor.withValues(alpha: 0.12)
                          : AppConstants.warningOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (_user?.isPro ?? false) ? 'PRO' : 'FREE',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: (_user?.isPro ?? false)
                            ? AppConstants.primaryColor
                            : AppConstants.warningOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Platform label
              Text(
                'Your Platforms',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textDark,
                ),
              ),
              const SizedBox(height: 16),

              // Facebook Card
              PlatformCard(
                icon: Icons.facebook,
                title: 'Facebook Auto DM',
                subtitle: 'Auto-reply to comments & send DMs',
                activeRules: _fbRulesCount,
                gradientColors: const [
                  AppConstants.facebookBlue,
                  Color(0xFF4267B2),
                ],
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PlatformScreen(platform: 'facebook'),
                    ),
                  );
                  _loadData();
                },
              ),
              const SizedBox(height: 16),

              // Instagram Card
              PlatformCard(
                icon: Icons.camera_alt_rounded,
                title: 'Instagram Auto DM',
                subtitle: 'Auto-reply to comments & send DMs',
                activeRules: _igRulesCount,
                gradientColors: const [
                  AppConstants.instagramPurple,
                  AppConstants.instagramPink,
                  AppConstants.instagramOrange,
                ],
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PlatformScreen(platform: 'instagram'),
                    ),
                  );
                  _loadData();
                },
              ),
              const SizedBox(height: 24),

              // Upgrade Banner
              if (!(_user?.isPro ?? false))
                UpgradeBanner(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                    );
                    _loadData();
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
