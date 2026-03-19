import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../models/automation_model.dart';

class AutomationScreen extends StatefulWidget {
  final String platform;
  final String pageId;
  final String pageName;
  final String? postId;
  final String? postCaption;
  final AutomationModel? existingRule;

  const AutomationScreen({
    super.key,
    required this.platform,
    required this.pageId,
    required this.pageName,
    this.postId,
    this.postCaption,
    this.existingRule,
  });

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  bool get isEditing => widget.existingRule != null;
  bool get isFacebook => widget.platform == 'facebook';
  bool _isSaving = false;
  bool _isPro = false; // Will be fetched from user data

  // Form fields
  String _triggerType = 'all';
  String _replyType = 'fixed';
  bool _autoDmEnabled = false;
  bool _requireFollow = false;

  final _keywordsController = TextEditingController();
  final _replyMessageController = TextEditingController();
  final _aiPromptController = TextEditingController();
  final _dmMessageController = TextEditingController();
  final _fileUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserPlan();
    if (isEditing) {
      final rule = widget.existingRule!;
      _triggerType = rule.triggerType;
      _replyType = rule.replyType;
      _autoDmEnabled = rule.autoDmEnabled;
      _requireFollow = rule.requireFollow;
      _keywordsController.text = rule.keywords.join(', ');
      _replyMessageController.text = rule.replyMessage;
      _aiPromptController.text = rule.aiPrompt ?? '';
      _dmMessageController.text = rule.dmMessage ?? '';
      _fileUrlController.text = rule.fileUrl ?? '';
    }
  }

  Future<void> _loadUserPlan() async {
    final user = await ApiService.getMe();
    if (user != null && mounted) {
      setState(() => _isPro = user.isPro);
    }
  }

  @override
  void dispose() {
    _keywordsController.dispose();
    _replyMessageController.dispose();
    _aiPromptController.dispose();
    _dmMessageController.dispose();
    _fileUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_replyType == 'fixed' && _replyMessageController.text.trim().isEmpty) {
      _showError('Please enter a reply message');
      return;
    }
    if (_triggerType == 'keyword' && _keywordsController.text.trim().isEmpty) {
      _showError('Please enter at least one keyword');
      return;
    }
    if (_replyType == 'ai' && _aiPromptController.text.trim().isEmpty) {
      _showError('Please enter an AI prompt');
      return;
    }
    if (_requireFollow && _fileUrlController.text.trim().isEmpty) {
      _showError('Please enter the file/reward URL');
      return;
    }

    setState(() => _isSaving = true);

    final keywords = _keywordsController.text
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();

    final rule = AutomationModel(
      pageId: widget.pageId,
      postId: widget.postId ?? widget.existingRule?.postId,
      platform: widget.platform,
      triggerType: _triggerType,
      keywords: keywords,
      replyType: _replyType,
      replyMessage: _replyMessageController.text.trim(),
      aiPrompt: _aiPromptController.text.trim().isNotEmpty
          ? _aiPromptController.text.trim()
          : null,
      autoDmEnabled: _autoDmEnabled,
      dmMessage: _dmMessageController.text.trim().isNotEmpty
          ? _dmMessageController.text.trim()
          : null,
      requireFollow: _requireFollow,
      fileUrl: _fileUrlController.text.trim().isNotEmpty
          ? _fileUrlController.text.trim()
          : null,
    );

    bool success;
    if (isEditing && widget.existingRule?.id != null) {
      success = await ApiService.updateAutomationRule(
        widget.existingRule!.id!,
        rule.toJson(),
      );
    } else {
      final created = await ApiService.createAutomationRule(rule);
      success = created != null;
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Rule updated!' : 'Rule created!'),
          backgroundColor: AppConstants.successGreen,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      _showError('Failed to save rule. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppConstants.errorRed),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          isEditing ? 'Edit Rule' : 'New Automation Rule',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppConstants.textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform & Page Info
            _buildInfoCard(),
            const SizedBox(height: 24),

            // Trigger Type
            _buildSectionTitle('Trigger Type'),
            const SizedBox(height: 12),
            _buildTriggerOptions(),
            const SizedBox(height: 8),

            // Keywords (conditional)
            if (_triggerType == 'keyword') ...[
              const SizedBox(height: 12),
              _buildTextField(
                controller: _keywordsController,
                label: 'Keywords',
                hint: 'Enter keywords, separated by commas',
                icon: Icons.text_fields,
              ),
            ],
            const SizedBox(height: 24),

            // Reply Type
            _buildSectionTitle('Reply Type'),
            const SizedBox(height: 12),
            _buildReplyOptions(),
            const SizedBox(height: 12),

            // Reply Message or AI Prompt
            if (_replyType == 'fixed')
              _buildTextField(
                controller: _replyMessageController,
                label: 'Reply Message',
                hint: 'Enter the message to reply with...',
                icon: Icons.message_outlined,
                maxLines: 4,
              ),
            if (_replyType == 'ai')
              _buildTextField(
                controller: _aiPromptController,
                label: 'AI Prompt',
                hint: 'e.g., Reply professionally, thank them and ask to check DM...',
                icon: Icons.psychology_outlined,
                maxLines: 4,
              ),
            const SizedBox(height: 24),

            // Auto DM
            _buildSectionTitle('Auto DM'),
            const SizedBox(height: 12),
            _buildAutoDmToggle(),

            if (_autoDmEnabled) ...[
              const SizedBox(height: 12),
              _buildTextField(
                controller: _dmMessageController,
                label: 'DM Message',
                hint: 'e.g., Hey! Here\'s the content you asked for',
                icon: Icons.send_outlined,
                maxLines: 4,
              ),

              // Follow Gate (Instagram only)
              if (!isFacebook) ...[
                const SizedBox(height: 20),
                _buildSectionTitle('Follow Gate'),
                const SizedBox(height: 8),
                Text(
                  'Only send the file/reward after they follow your account',
                  style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textSecondary),
                ),
                const SizedBox(height: 12),
                _buildFollowGateToggle(),
                if (_requireFollow) ...[
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _fileUrlController,
                    label: 'File / Reward URL',
                    hint: 'https://drive.google.com/your-file-link',
                    icon: Icons.attach_file_rounded,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: AppConstants.primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Commenter gets a friendly "check DM" reply. In DM they tap "Get Content" → we ask them to follow first → they tap "I\'m already following" → we verify → file sent!',
                            style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isEditing ? 'Update Rule' : 'Save Rule',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        children: [
          _buildInfoRow(
            'Platform',
            isFacebook ? 'Facebook' : 'Instagram',
            isFacebook ? Icons.facebook : Icons.camera_alt_rounded,
            isFacebook ? AppConstants.facebookBlue : AppConstants.instagramPink,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            isFacebook ? 'Page' : 'Account',
            widget.pageName,
            Icons.account_circle_outlined,
            AppConstants.textDark,
          ),
          if (widget.postCaption != null) ...[
            const Divider(height: 24),
            _buildInfoRow(
              'Post',
              widget.postCaption!.length > 60
                  ? '${widget.postCaption!.substring(0, 60)}...'
                  : widget.postCaption!,
              Icons.article_outlined,
              AppConstants.textDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(fontSize: 11, color: AppConstants.textSecondary)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppConstants.textDark,
      ),
    );
  }

  Widget _buildTriggerOptions() {
    return Column(
      children: [
        _buildOptionTile(
          title: 'All Comments',
          subtitle: 'Reply to every comment on this post',
          icon: Icons.comment_rounded,
          isSelected: _triggerType == 'all',
          onTap: () => setState(() => _triggerType = 'all'),
        ),
        const SizedBox(height: 8),
        _buildOptionTile(
          title: 'Keyword Match',
          subtitle: 'Reply only when keywords are found',
          icon: Icons.text_fields_rounded,
          isSelected: _triggerType == 'keyword',
          onTap: () => setState(() => _triggerType = 'keyword'),
        ),
        const SizedBox(height: 8),
        _buildOptionTile(
          title: 'AI Smart Match',
          subtitle: 'Use AI to detect relevant comments',
          icon: Icons.psychology_rounded,
          isSelected: _triggerType == 'ai',
          isPro: true,
          onTap: () {
            if (_isPro) {
              setState(() => _triggerType = 'ai');
            } else {
              _showError('Upgrade to Pro to use AI Smart Match');
            }
          },
        ),
      ],
    );
  }

  Widget _buildReplyOptions() {
    return Column(
      children: [
        _buildOptionTile(
          title: 'Fixed Message',
          subtitle: 'Send the same reply every time',
          icon: Icons.message_rounded,
          isSelected: _replyType == 'fixed',
          onTap: () => setState(() => _replyType = 'fixed'),
        ),
        const SizedBox(height: 8),
        _buildOptionTile(
          title: 'AI Generated',
          subtitle: 'Generate unique replies with AI',
          icon: Icons.auto_awesome_rounded,
          isSelected: _replyType == 'ai',
          isPro: true,
          onTap: () {
            if (_isPro) {
              setState(() => _replyType = 'ai');
            } else {
              _showError('Upgrade to Pro to use AI Generated replies');
            }
          },
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    bool isPro = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withValues(alpha: 0.06)
              : AppConstants.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.grey.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppConstants.primaryColor : AppConstants.textSecondary,
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textDark,
                        ),
                      ),
                      if (isPro && !_isPro) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConstants.secondaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, size: 10, color: AppConstants.secondaryColor),
                              const SizedBox(width: 2),
                              Text(
                                'PRO',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppConstants.secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppConstants.primaryColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowGateToggle() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _requireFollow
            ? AppConstants.instagramPink.withValues(alpha: 0.06)
            : AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _requireFollow
              ? AppConstants.instagramPink
              : Colors.grey.withValues(alpha: 0.15),
          width: _requireFollow ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded,
              color: _requireFollow ? AppConstants.instagramPink : AppConstants.textSecondary,
              size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Require Follow to Get File',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textDark,
                  ),
                ),
                Text(
                  'File sent only after they follow + reply "DONE"',
                  style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textSecondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _requireFollow,
            onChanged: (val) => setState(() => _requireFollow = val),
            activeTrackColor: AppConstants.instagramPink.withValues(alpha: 0.5),
            activeThumbColor: AppConstants.instagramPink,
          ),
        ],
      ),
    );
  }

  Widget _buildAutoDmToggle() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.send_rounded, color: AppConstants.primaryColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Enable Auto DM',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textDark,
                      ),
                    ),
                    if (!_isPro) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppConstants.secondaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 10, color: AppConstants.secondaryColor),
                            const SizedBox(width: 2),
                            Text(
                              'PRO',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Send a DM after replying to the comment',
                  style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textSecondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _autoDmEnabled,
            onChanged: (val) {
              if (!_isPro && val) {
                _showError('Upgrade to Pro to use Auto DM');
                return;
              }
              setState(() => _autoDmEnabled = val);
            },
            activeTrackColor: AppConstants.primaryColor.withValues(alpha: 0.5),
            activeThumbColor: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14, color: AppConstants.textDark),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(color: AppConstants.textSecondary),
        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppConstants.textSecondary.withValues(alpha: 0.6)),
        prefixIcon: maxLines == 1 ? Icon(icon, color: AppConstants.primaryColor, size: 20) : null,
        filled: true,
        fillColor: AppConstants.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
      ),
    );
  }
}
