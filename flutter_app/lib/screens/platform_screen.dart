import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../models/page_model.dart';
import '../models/post_model.dart';
import '../models/automation_model.dart';
import '../models/instagram_account_model.dart';
import '../widgets/loading_widget.dart';
import 'automation_screen.dart';
import 'bulk_reply_screen.dart';

class PlatformScreen extends StatefulWidget {
  final String platform;

  const PlatformScreen({super.key, required this.platform});

  @override
  State<PlatformScreen> createState() => _PlatformScreenState();
}

class _PlatformScreenState extends State<PlatformScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool get isFacebook => widget.platform == 'facebook';

  // Accounts/Pages
  List<PageModel> _pages = [];
  List<InstagramAccountModel> _igAccounts = [];
  bool _loadingAccounts = true;

  // Selected
  String? _selectedAccountId;
  String? _selectedAccountName;

  // Posts/Media
  List<PostModel> _posts = [];
  bool _loadingPosts = false;

  // Automation Rules
  List<AutomationModel> _rules = [];
  bool _loadingRules = false;

  // User plan
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAccounts();
    _loadUserPlan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPlan() async {
    final user = await ApiService.getMe();
    if (user != null && mounted) {
      setState(() => _isPro = user.isPro);
    }
  }

  Future<void> _loadAccounts() async {
    setState(() => _loadingAccounts = true);
    if (isFacebook) {
      _pages = await ApiService.getPages();
    } else {
      _igAccounts = await ApiService.getInstagramAccounts();
    }
    setState(() => _loadingAccounts = false);
  }

  Future<void> _selectAccount(String id, String name) async {
    setState(() {
      _selectedAccountId = id;
      _selectedAccountName = name;
    });
    await Future.wait([_loadPosts(id), _loadRules(id)]);
    if (_tabController.index == 0) {
      _tabController.animateTo(1);
    }
  }

  Future<void> _loadPosts(String id) async {
    setState(() => _loadingPosts = true);
    if (isFacebook) {
      _posts = await ApiService.getPosts(id);
    } else {
      _posts = await ApiService.getInstagramMedia(id);
    }
    setState(() => _loadingPosts = false);
  }

  Future<void> _loadRules(String id) async {
    setState(() => _loadingRules = true);
    _rules = await ApiService.getAutomationRules(
      pageId: id,
      platform: widget.platform,
    );
    setState(() => _loadingRules = false);
  }

  Future<void> _deleteRule(String ruleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Rule'),
        content: const Text('Are you sure you want to delete this automation rule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppConstants.errorRed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.deleteAutomationRule(ruleId);
      if (success && _selectedAccountId != null) {
        _loadRules(_selectedAccountId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rule deleted'), backgroundColor: AppConstants.successGreen),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete rule'), backgroundColor: AppConstants.errorRed),
        );
      }
    }
  }

  Future<void> _toggleRule(AutomationModel rule) async {
    final success = await ApiService.updateAutomationRule(
      rule.id!,
      {'isActive': !rule.isActive},
    );
    if (success && _selectedAccountId != null) {
      _loadRules(_selectedAccountId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformTitle = isFacebook ? 'Facebook' : 'Instagram';
    final platformColor = isFacebook ? AppConstants.facebookBlue : AppConstants.instagramPink;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppConstants.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(
              isFacebook ? Icons.facebook : Icons.camera_alt_rounded,
              color: platformColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '$platformTitle Auto DM',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textDark,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: AppConstants.textSecondary,
          indicatorColor: AppConstants.primaryColor,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: isFacebook ? 'Pages' : 'Accounts'),
            const Tab(text: 'Posts'),
            const Tab(text: 'Rules'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 2 && _selectedAccountId != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AutomationScreen(
                      platform: widget.platform,
                      pageId: _selectedAccountId!,
                      pageName: _selectedAccountName ?? '',
                    ),
                  ),
                );
                if (_selectedAccountId != null) {
                  _loadRules(_selectedAccountId!);
                }
              },
              backgroundColor: AppConstants.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'New Rule',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAccountsTab(),
          _buildPostsTab(),
          _buildRulesTab(),
        ],
      ),
    );
  }

  // ─── Tab 1: Accounts/Pages ───

  Widget _buildAccountsTab() {
    if (_loadingAccounts) {
      return const LoadingWidget(message: 'Loading accounts...');
    }

    final items = isFacebook ? _pages : _igAccounts;

    if (items.isEmpty) {
      return EmptyStateWidget(
        icon: isFacebook ? Icons.facebook : Icons.camera_alt_rounded,
        title: 'No ${isFacebook ? 'pages' : 'accounts'} found',
        subtitle: 'Sync your ${isFacebook ? 'Facebook pages' : 'Instagram accounts'} to get started',
      );
    }

    return Column(
      children: [
        // Sync button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loadAccounts,
              icon: const Icon(Icons.sync_rounded),
              label: Text('Sync ${isFacebook ? 'Pages' : 'Accounts'}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                side: const BorderSide(color: AppConstants.primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: isFacebook ? _pages.length : _igAccounts.length,
            itemBuilder: (context, index) {
              if (isFacebook) {
                final page = _pages[index];
                return _buildAccountTile(
                  id: page.id,
                  name: page.name,
                  profilePic: page.profilePic,
                  subtitle: page.category ?? 'Facebook Page',
                  followerCount: page.followerCount,
                );
              } else {
                final account = _igAccounts[index];
                return _buildAccountTile(
                  id: account.id,
                  name: account.name,
                  profilePic: account.profilePic,
                  subtitle: account.username != null ? '@${account.username}' : 'Instagram Account',
                  followerCount: account.followerCount,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTile({
    required String id,
    required String name,
    String? profilePic,
    required String subtitle,
    int? followerCount,
  }) {
    final isSelected = _selectedAccountId == id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: isSelected
            ? Border.all(color: AppConstants.primaryColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
          backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
          child: profilePic == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryColor,
                  ),
                )
              : null,
        ),
        title: Text(
          name,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppConstants.textDark),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (followerCount != null)
              Text(
                _formatCount(followerCount),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textDark,
                ),
              ),
            if (followerCount != null)
              Text(
                'followers',
                style: GoogleFonts.inter(fontSize: 11, color: AppConstants.textSecondary),
              ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppConstants.primaryColor, size: 20),
          ],
        ),
        onTap: () => _selectAccount(id, name),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  // ─── Tab 2: Posts ───

  Widget _buildPostsTab() {
    if (_selectedAccountId == null) {
      return const EmptyStateWidget(
        icon: Icons.touch_app_rounded,
        title: 'Select an account first',
        subtitle: 'Go to the Accounts tab and select a page or account',
      );
    }

    if (_loadingPosts) {
      return const LoadingWidget(message: 'Loading posts...');
    }

    if (_posts.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.article_outlined,
        title: 'No posts found',
        subtitle: 'This account has no posts yet',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPosts(_selectedAccountId!),
      color: AppConstants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _buildPostTile(post);
        },
      ),
    );
  }

  Widget _buildPostTile(PostModel post) {
    final hasImage = (post.imageUrl ?? post.mediaUrl) != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                (post.imageUrl ?? post.mediaUrl)!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => Container(
                  height: 100,
                  color: AppConstants.backgroundColor,
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        color: AppConstants.textSecondary),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.displayText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppConstants.textDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (post.createdTime != null) ...[
                      Icon(Icons.access_time, size: 14, color: AppConstants.textSecondary.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(post.createdTime!),
                        style: GoogleFonts.inter(fontSize: 11, color: AppConstants.textSecondary),
                      ),
                    ],
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        if (!_isPro) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Upgrade to Pro to use Bulk Reply'),
                              backgroundColor: AppConstants.warningOrange,
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BulkReplyScreen(
                              platform: widget.platform,
                              postId: post.id,
                              pageId: isFacebook ? _selectedAccountId : null,
                              accountId: !isFacebook ? _selectedAccountId : null,
                              postCaption: post.displayText,
                            ),
                          ),
                        );
                      },
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.reply_all_rounded, size: 16),
                          Positioned(
                            top: -4,
                            right: -6,
                            child: Icon(
                              Icons.workspace_premium,
                              size: 10,
                              color: AppConstants.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      label: const Text('Bulk Reply'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppConstants.secondaryColor,
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AutomationScreen(
                              platform: widget.platform,
                              pageId: _selectedAccountId!,
                              pageName: _selectedAccountName ?? '',
                              postId: post.id,
                              postCaption: post.displayText,
                            ),
                          ),
                        ).then((_) {
                          if (_selectedAccountId != null) _loadRules(_selectedAccountId!);
                        });
                      },
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Automate'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppConstants.primaryColor,
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 30) return '${date.day}/${date.month}/${date.year}';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return '${diff.inMinutes}m ago';
    } catch (_) {
      return dateStr;
    }
  }

  // ─── Tab 3: Rules ───

  Widget _buildRulesTab() {
    if (_selectedAccountId == null) {
      return const EmptyStateWidget(
        icon: Icons.touch_app_rounded,
        title: 'Select an account first',
        subtitle: 'Go to the Accounts tab and select a page or account',
      );
    }

    if (_loadingRules) {
      return const LoadingWidget(message: 'Loading rules...');
    }

    if (_rules.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.auto_awesome_outlined,
        title: 'No automation rules yet',
        subtitle: 'Tap the + button to create your first rule',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadRules(_selectedAccountId!),
      color: AppConstants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rules.length,
        itemBuilder: (context, index) {
          final rule = _rules[index];
          return Dismissible(
            key: Key(rule.id ?? index.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppConstants.errorRed,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              if (rule.id != null) {
                await _deleteRule(rule.id!);
              }
              return false; // We handle refresh in _deleteRule
            },
            child: _buildRuleTile(rule),
          );
        },
      ),
    );
  }

  Widget _buildRuleTile(AutomationModel rule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: rule.isActive
                ? AppConstants.successGreen.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            rule.triggerType == 'ai'
                ? Icons.psychology
                : rule.triggerType == 'keyword'
                    ? Icons.text_fields
                    : Icons.comment,
            color: rule.isActive ? AppConstants.successGreen : Colors.grey,
          ),
        ),
        title: Text(
          rule.triggerLabel,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppConstants.textDark),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reply: ${rule.replyLabel}',
              style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textSecondary),
            ),
            if (rule.autoDmEnabled)
              Text(
                'Auto DM enabled',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: Switch.adaptive(
          value: rule.isActive,
          onChanged: (_) => _toggleRule(rule),
          activeTrackColor: AppConstants.successGreen.withValues(alpha: 0.5),
          activeThumbColor: AppConstants.successGreen,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AutomationScreen(
                platform: widget.platform,
                pageId: _selectedAccountId!,
                pageName: _selectedAccountName ?? '',
                existingRule: rule,
              ),
            ),
          ).then((_) {
            if (_selectedAccountId != null) _loadRules(_selectedAccountId!);
          });
        },
      ),
    );
  }
}
