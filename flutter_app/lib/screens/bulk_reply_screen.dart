import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';

class BulkReplyScreen extends StatefulWidget {
  final String platform;
  final String postId;
  final String? pageId;
  final String? accountId;
  final String? postCaption;

  const BulkReplyScreen({
    super.key,
    required this.platform,
    required this.postId,
    this.pageId,
    this.accountId,
    this.postCaption,
  });

  @override
  State<BulkReplyScreen> createState() => _BulkReplyScreenState();
}

class _BulkReplyScreenState extends State<BulkReplyScreen>
    with SingleTickerProviderStateMixin {
  bool get isFacebook => widget.platform == 'facebook';

  // Comments
  List<dynamic> _comments = [];
  bool _loadingComments = false;
  bool _commentsFetched = false;
  Set<int> _selectedIndices = {};

  // Reply config
  String _replyType = 'fixed';
  bool _autoDmEnabled = false;
  final _replyMessageController = TextEditingController();
  final _aiPromptController = TextEditingController();
  final _dmMessageController = TextEditingController();

  // Delay settings
  double _minDelay = 30;
  double _maxDelay = 120;

  // Job tracking
  String? _activeJobId;
  Map<String, dynamic>? _jobStatus;
  bool _isStarting = false;
  Timer? _pollTimer;

  // Animation
  late AnimationController _progressAnimController;
  late Animation<double> _progressAnimation;
  double _lastProgress = 0;

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _replyMessageController.dispose();
    _aiPromptController.dispose();
    _dmMessageController.dispose();
    _progressAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    setState(() => _loadingComments = true);
    final comments = await ApiService.fetchComments(
      widget.postId,
      widget.platform,
      pageId: widget.pageId,
      accountId: widget.accountId,
    );
    if (mounted) {
      setState(() {
        _comments = comments;
        _commentsFetched = true;
        _loadingComments = false;
        _selectedIndices = Set<int>.from(
          List.generate(comments.length, (i) => i),
        );
      });
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIndices.length == _comments.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices = Set<int>.from(
          List.generate(_comments.length, (i) => i),
        );
      }
    });
  }

  String _estimateTime(int count) {
    final avgDelay = (_minDelay + _maxDelay) / 2;
    final totalSeconds = (count * avgDelay).round();
    if (totalSeconds < 60) return '${totalSeconds}s';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes < 60) return '${minutes}m ${seconds}s';
    final hours = minutes ~/ 60;
    final remainMinutes = minutes % 60;
    return '${hours}h ${remainMinutes}m';
  }

  Future<void> _startBulkReply() async {
    if (_selectedIndices.isEmpty) {
      _showError('Please select at least one comment');
      return;
    }
    if (_replyType == 'fixed' && _replyMessageController.text.trim().isEmpty) {
      _showError('Please enter a reply message');
      return;
    }
    if (_replyType == 'ai' && _aiPromptController.text.trim().isEmpty) {
      _showError('Please enter an AI prompt');
      return;
    }

    final selectedCount = _selectedIndices.length;
    final estimatedTime = _estimateTime(selectedCount);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Start Bulk Reply',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Reply to $selectedCount comments with random ${_minDelay.round()}-${_maxDelay.round()}s delays. '
          'This will take approximately $estimatedTime. Continue?',
          style: GoogleFonts.inter(fontSize: 14, color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppConstants.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Start', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isStarting = true);

    final selectedComments = _selectedIndices
        .map((i) => _comments[i])
        .toList();

    final body = <String, dynamic>{
      'postId': widget.postId,
      'platform': widget.platform,
      if (widget.pageId != null) 'pageId': widget.pageId,
      if (widget.accountId != null) 'accountId': widget.accountId,
      'comments': selectedComments,
      'replyType': _replyType,
      'replyMessage': _replyMessageController.text.trim(),
      'aiPrompt': _aiPromptController.text.trim(),
      'autoDmEnabled': _autoDmEnabled,
      'dmMessage': _dmMessageController.text.trim(),
      'minDelay': _minDelay.round(),
      'maxDelay': _maxDelay.round(),
    };

    final result = await ApiService.startBulkReply(body);

    if (mounted) {
      setState(() => _isStarting = false);

      if (result != null) {
        final jobId = result['jobId'] ?? result['job_id'] ?? result['id'];
        if (jobId != null) {
          setState(() {
            _activeJobId = jobId.toString();
            _jobStatus = result;
          });
          _startPolling();
        }
      } else {
        _showError('Failed to start bulk reply. Please try again.');
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollJobStatus());
  }

  Future<void> _pollJobStatus() async {
    if (_activeJobId == null) return;
    final status = await ApiService.getJobStatus(_activeJobId!);
    if (status != null && mounted) {
      final jobStatus = status['status'] ?? status['job']?['status'];
      setState(() {
        _jobStatus = status;
        _updateProgressAnimation();
      });
      if (jobStatus == 'completed' || jobStatus == 'failed') {
        _pollTimer?.cancel();
      }
    }
  }

  void _updateProgressAnimation() {
    if (_jobStatus == null) return;
    final job = _jobStatus!['job'] ?? _jobStatus!;
    final replied = (job['replied_count'] ?? job['repliedCount'] ?? 0) as num;
    final total = (job['total_comments'] ?? job['totalComments'] ?? 1) as num;
    final newProgress = total > 0 ? replied / total : 0.0;

    _progressAnimation = Tween<double>(
      begin: _lastProgress,
      end: newProgress,
    ).animate(CurvedAnimation(
      parent: _progressAnimController,
      curve: Curves.easeInOut,
    ));
    _progressAnimController.forward(from: 0);
    _lastProgress = newProgress;
  }

  Future<void> _togglePauseResume() async {
    if (_activeJobId == null || _jobStatus == null) return;
    final job = _jobStatus!['job'] ?? _jobStatus!;
    final status = job['status'] as String?;

    bool success;
    if (status == 'paused') {
      success = await ApiService.resumeJob(_activeJobId!);
    } else {
      success = await ApiService.pauseJob(_activeJobId!);
    }

    if (success) {
      await _pollJobStatus();
    } else if (mounted) {
      _showError('Failed to ${status == "paused" ? "resume" : "pause"} job');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
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
        title: Row(
          children: [
            Icon(
              isFacebook ? Icons.facebook : Icons.camera_alt_rounded,
              color: isFacebook ? AppConstants.facebookBlue : AppConstants.instagramPink,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Bulk Reply',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium, size: 12, color: Colors.white),
                  const SizedBox(width: 2),
                  Text(
                    'PRO',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _activeJobId != null ? _buildJobProgress() : _buildSetup(),
    );
  }

  // ─── Section A: Setup & Start ───

  Widget _buildSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post info header
          _buildPostInfoCard(),
          const SizedBox(height: 20),

          // Fetch comments button
          if (!_commentsFetched)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _loadingComments ? null : _fetchComments,
                icon: _loadingComments
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  _loadingComments ? 'Fetching...' : 'Fetch Comments',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),

          // Comments list
          if (_commentsFetched) ...[
            _buildCommentsSection(),
            const SizedBox(height: 24),
            _buildReplyConfigSection(),
            const SizedBox(height: 24),
            _buildDelaySection(),
            const SizedBox(height: 32),
            _buildStartButton(),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPostInfoCard() {
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
          Row(
            children: [
              Icon(
                Icons.article_outlined,
                color: AppConstants.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Post',
                      style: GoogleFonts.inter(fontSize: 11, color: AppConstants.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.postCaption != null && widget.postCaption!.length > 80
                          ? '${widget.postCaption!.substring(0, 80)}...'
                          : widget.postCaption ?? widget.postId,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isFacebook ? AppConstants.facebookBlue : AppConstants.instagramPink)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isFacebook ? 'Facebook' : 'Instagram',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isFacebook ? AppConstants.facebookBlue : AppConstants.instagramPink,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    if (_comments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.comment_outlined, size: 48, color: AppConstants.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(
                'No comments found',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This post has no comments to reply to',
                style: GoogleFonts.inter(fontSize: 13, color: AppConstants.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final allSelected = _selectedIndices.length == _comments.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with select toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Comments (${_comments.length})',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.textDark,
              ),
            ),
            TextButton.icon(
              onPressed: _toggleSelectAll,
              icon: Icon(
                allSelected ? Icons.deselect : Icons.select_all,
                size: 18,
              ),
              label: Text(allSelected ? 'Deselect All' : 'Select All'),
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Selected count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${_selectedIndices.length} of ${_comments.length} selected',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppConstants.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Comments list (constrained height)
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _comments.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.grey.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, index) {
                final comment = _comments[index];
                final isSelected = _selectedIndices.contains(index);
                final name = comment['from']?['name'] ??
                    comment['username'] ??
                    comment['commenter_name'] ??
                    'Unknown';
                final text = comment['message'] ??
                    comment['text'] ??
                    comment['comment'] ??
                    '';
                final timestamp = comment['created_time'] ??
                    comment['timestamp'] ??
                    '';

                return Material(
                  color: isSelected
                      ? AppConstants.primaryColor.withValues(alpha: 0.04)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedIndices.remove(index);
                        } else {
                          _selectedIndices.add(index);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIndices.add(index);
                                } else {
                                  _selectedIndices.remove(index);
                                }
                              });
                            },
                            activeColor: AppConstants.primaryColor,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name.toString(),
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (timestamp.toString().isNotEmpty)
                                      Text(
                                        _formatTimestamp(timestamp.toString()),
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: AppConstants.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  text.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppConstants.textSecondary,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReplyConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reply Configuration',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textDark,
          ),
        ),
        const SizedBox(height: 12),

        // Reply type
        _buildOptionTile(
          title: 'Fixed Message',
          subtitle: 'Send the same reply to all selected comments',
          icon: Icons.message_rounded,
          isSelected: _replyType == 'fixed',
          onTap: () => setState(() => _replyType = 'fixed'),
        ),
        const SizedBox(height: 8),
        _buildOptionTile(
          title: 'AI Generated',
          subtitle: 'Generate unique replies for each comment',
          icon: Icons.auto_awesome_rounded,
          isSelected: _replyType == 'ai',
          onTap: () => setState(() => _replyType = 'ai'),
        ),
        const SizedBox(height: 12),

        // Reply message / AI prompt
        if (_replyType == 'fixed')
          _buildTextField(
            controller: _replyMessageController,
            label: 'Reply Message',
            hint: 'Enter the message to reply with...',
            icon: Icons.message_outlined,
            maxLines: 3,
          ),
        if (_replyType == 'ai')
          _buildTextField(
            controller: _aiPromptController,
            label: 'AI Prompt',
            hint: 'e.g., Reply professionally, thank them and ask to check DM...',
            icon: Icons.psychology_outlined,
            maxLines: 3,
          ),
        const SizedBox(height: 16),

        // Auto DM toggle
        _buildAutoDmToggle(),

        if (_autoDmEnabled) ...[
          const SizedBox(height: 12),
          _buildTextField(
            controller: _dmMessageController,
            label: 'DM Message',
            hint: 'Enter the DM message to send...',
            icon: Icons.send_outlined,
            maxLines: 3,
          ),
        ],
      ],
    );
  }

  Widget _buildDelaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delay Settings',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
              // Min delay
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Min delay',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.textDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_minDelay.round()}s',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _minDelay,
                min: 10,
                max: 60,
                divisions: 10,
                activeColor: AppConstants.primaryColor,
                onChanged: (val) {
                  setState(() {
                    _minDelay = val;
                    if (_maxDelay < _minDelay) _maxDelay = _minDelay;
                  });
                },
              ),

              const SizedBox(height: 8),

              // Max delay
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Max delay',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.textDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_maxDelay.round()}s',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _maxDelay,
                min: 30,
                max: 180,
                divisions: 15,
                activeColor: AppConstants.primaryColor,
                onChanged: (val) {
                  setState(() {
                    _maxDelay = val;
                    if (_minDelay > _maxDelay) _minDelay = _maxDelay;
                  });
                },
              ),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.warningOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppConstants.warningOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Random delay between ${_minDelay.round()}s - ${_maxDelay.round()}s per reply to appear human',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppConstants.warningOrange,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppConstants.primaryColor, Color(0xFF8B5CF6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: (_isStarting || _selectedIndices.isEmpty) ? null : _startBulkReply,
          icon: _isStarting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow_rounded, size: 24),
          label: Text(
            _isStarting
                ? 'Starting...'
                : 'Start Bulk Reply (${_selectedIndices.length} comments)',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  // ─── Section B: Job Progress ───

  Widget _buildJobProgress() {
    if (_jobStatus == null) {
      return const LoadingWidget(message: 'Loading job status...');
    }

    final job = _jobStatus!['job'] ?? _jobStatus!;
    final status = (job['status'] ?? 'running') as String;
    final repliedCount = (job['replied_count'] ?? job['repliedCount'] ?? 0) as num;
    final totalComments = (job['total_comments'] ?? job['totalComments'] ?? 0) as num;
    final failedCount = (job['failed_count'] ?? job['failedCount'] ?? 0) as num;
    final comments = (job['comments'] ?? job['comment_statuses'] ?? []) as List;

    final isRunning = status == 'running' || status == 'in_progress';
    final isPaused = status == 'paused';
    final isCompleted = status == 'completed';
    final isFailed = status == 'failed';

    final remaining = totalComments - repliedCount - failedCount;
    final avgDelay = (_minDelay + _maxDelay) / 2;
    final remainingSeconds = (remaining * avgDelay).round();
    final estimatedRemaining = _formatDuration(remainingSeconds);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                // Status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Job Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textDark,
                      ),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 20),

                // Animated progress bar
                AnimatedBuilder(
                  animation: _progressAnimController,
                  builder: (context, child) {
                    final progress = totalComments > 0
                        ? _progressAnimation.value
                        : 0.0;
                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted
                                  ? AppConstants.successGreen
                                  : isFailed
                                      ? AppConstants.errorRed
                                      : AppConstants.primaryColor,
                            ),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${repliedCount.toInt()} / ${totalComments.toInt()} replied',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.textDark,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Replied', repliedCount.toInt().toString(), AppConstants.successGreen),
                    _buildStatItem('Failed', failedCount.toInt().toString(), AppConstants.errorRed),
                    _buildStatItem('Remaining', remaining.toInt().toString(), AppConstants.warningOrange),
                  ],
                ),

                if ((isRunning || isPaused) && remaining > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: AppConstants.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          'Est. remaining: $estimatedRemaining',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pause/Resume button
          if (isRunning || isPaused)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _togglePauseResume,
                icon: Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 22,
                ),
                label: Text(
                  isPaused ? 'Resume Job' : 'Pause Job',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPaused ? AppConstants.successGreen : AppConstants.warningOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Comment statuses
          if (comments.isNotEmpty) ...[
            Text(
              'Comment Status',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                  itemBuilder: (context, index) {
                    final c = comments[index];
                    final cStatus = (c['status'] ?? 'pending') as String;
                    final commentText = c['message'] ?? c['text'] ?? c['comment'] ?? '';
                    final replyText = c['reply_sent'] ?? c['replySent'] ?? '';
                    final dmSent = c['dm_sent'] ?? c['dmSent'] ?? false;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCommentStatusIcon(cStatus),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  commentText.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppConstants.textDark,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (replyText.toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.reply, size: 12, color: AppConstants.successGreen),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          replyText.toString(),
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppConstants.successGreen,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (dmSent == true) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'DM Sent',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'running':
      case 'in_progress':
        color = AppConstants.successGreen;
        icon = Icons.play_circle_filled;
        label = 'Running';
        break;
      case 'paused':
        color = AppConstants.warningOrange;
        icon = Icons.pause_circle_filled;
        label = 'Paused';
        break;
      case 'completed':
        color = AppConstants.successGreen;
        icon = Icons.check_circle;
        label = 'Completed';
        break;
      case 'failed':
        color = AppConstants.errorRed;
        icon = Icons.error;
        label = 'Failed';
        break;
      default:
        color = AppConstants.textSecondary;
        icon = Icons.hourglass_empty;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentStatusIcon(String status) {
    switch (status) {
      case 'replied':
      case 'success':
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppConstants.successGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.check, size: 16, color: AppConstants.successGreen),
        );
      case 'failed':
      case 'error':
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppConstants.errorRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.close, size: 16, color: AppConstants.errorRed),
        );
      default:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.schedule, size: 16, color: AppConstants.textSecondary),
        );
    }
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes < 60) return '${minutes}m ${seconds}s';
    final hours = minutes ~/ 60;
    final remainMinutes = minutes % 60;
    return '${hours}h ${remainMinutes}m';
  }

  String _formatTimestamp(String dateStr) {
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

  // ─── Shared Widgets ───

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
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
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textDark,
                    ),
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
                Text(
                  'Enable Auto DM',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textDark,
                  ),
                ),
                Text(
                  'Send a DM after replying to each comment',
                  style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textSecondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _autoDmEnabled,
            onChanged: (val) => setState(() => _autoDmEnabled = val),
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
