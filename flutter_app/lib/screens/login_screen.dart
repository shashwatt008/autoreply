import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _loginWithFacebook() {
    setState(() => _isLoading = true);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FacebookWebView(
          onTokenReceived: (token) async {
            await AuthService.saveToken(token);
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
                (route) => false,
              );
            }
          },
          onError: () {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Login failed. Please try again.'),
                  backgroundColor: AppConstants.errorRed,
                ),
              );
            }
          },
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              // App Name
              Text(
                AppConstants.appName,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textDark,
                ),
              ),
              const SizedBox(height: 8),
              // Tagline
              Text(
                AppConstants.appTagline,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Features
              _buildFeatureChip(Icons.comment_rounded, 'Auto-reply to comments'),
              const SizedBox(height: 8),
              _buildFeatureChip(Icons.send_rounded, 'Send DMs automatically'),
              const SizedBox(height: 8),
              _buildFeatureChip(Icons.psychology_rounded, 'AI-powered responses'),
              const Spacer(flex: 2),
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loginWithFacebook,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.facebook, size: 24),
                  label: Text(
                    _isLoading ? 'Connecting...' : 'Continue with Facebook',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.facebookBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: AppConstants.facebookBlue.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We only access your pages & posts.\nYour data stays private.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppConstants.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppConstants.primaryColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FacebookWebView extends StatefulWidget {
  final Function(String token) onTokenReceived;
  final VoidCallback onError;

  const _FacebookWebView({
    required this.onTokenReceived,
    required this.onError,
  });

  @override
  State<_FacebookWebView> createState() => _FacebookWebViewState();
}

class _FacebookWebViewState extends State<_FacebookWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            // Intercept redirect with token
            if (url.contains('?token=') || url.contains('&token=')) {
              final uri = Uri.parse(url);
              final token = uri.queryParameters['token'];
              if (token != null && token.isNotEmpty) {
                widget.onTokenReceived(token);
                Navigator.of(context).pop();
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            // Only handle main frame errors
          },
        ),
      )
      ..loadRequest(Uri.parse('${AppConstants.apiBaseUrl}/auth/facebook'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sign in with Facebook',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConstants.facebookBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onError();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: AppConstants.facebookBlue,
              ),
            ),
        ],
      ),
    );
  }
}
