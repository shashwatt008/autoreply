class AutomationModel {
  final String? id;
  final String pageId;
  final String? postId;
  final String platform;
  final String triggerType; // 'all', 'keyword', 'ai'
  final List<String> keywords;
  final String replyType; // 'fixed', 'ai'
  final String replyMessage;
  final String? aiPrompt;
  final bool autoDmEnabled;
  final String? dmMessage;
  final bool requireFollow;
  final String? fileUrl;
  final bool isActive;
  final String? createdAt;

  AutomationModel({
    this.id,
    required this.pageId,
    this.postId,
    required this.platform,
    required this.triggerType,
    this.keywords = const [],
    required this.replyType,
    this.replyMessage = '',
    this.aiPrompt,
    this.autoDmEnabled = false,
    this.dmMessage,
    this.requireFollow = false,
    this.fileUrl,
    this.isActive = true,
    this.createdAt,
  });

  factory AutomationModel.fromJson(Map<String, dynamic> json) {
    return AutomationModel(
      id: json['_id'] ?? json['id'],
      pageId: json['pageId'] ?? json['page_id'] ?? '',
      postId: json['postId'] ?? json['post_id'],
      platform: json['platform'] ?? 'facebook',
      triggerType: json['triggerType'] ?? json['trigger_type'] ?? 'all',
      keywords: json['keywords'] != null
          ? List<String>.from(json['keywords'])
          : [],
      replyType: json['replyType'] ?? json['reply_type'] ?? 'fixed',
      replyMessage: json['reply_messages'] != null && (json['reply_messages'] as List).isNotEmpty
          ? (json['reply_messages'] as List).first.toString()
          : (json['replyMessage'] ?? json['reply_message'] ?? ''),
      aiPrompt: json['aiPrompt'] ?? json['ai_prompt'],
      autoDmEnabled: json['autoDmEnabled'] ?? json['auto_dm_enabled'] ?? json['enable_dm'] ?? false,
      dmMessage: json['dmMessage'] ?? json['dm_message'],
      requireFollow: json['requireFollow'] ?? json['require_follow'] ?? false,
      fileUrl: json['fileUrl'] ?? json['file_url'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: json['createdAt'] ?? json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page_id': pageId,
      if (postId != null) 'post_id': postId,
      'platform': platform,
      'trigger_type': triggerType,
      'keywords': keywords,
      'reply_type': replyType,
      'reply_messages': [replyMessage],
      if (aiPrompt != null) 'ai_prompt': aiPrompt,
      'enable_dm': autoDmEnabled,
      if (dmMessage != null) 'dm_message': dmMessage,
      'require_follow': requireFollow,
      if (fileUrl != null) 'file_url': fileUrl,
      'is_active': isActive,
    };
  }

  String get triggerLabel {
    switch (triggerType) {
      case 'all':
        return 'All Comments';
      case 'keyword':
        return 'Keyword Match';
      case 'ai':
        return 'AI Smart Match';
      default:
        return triggerType;
    }
  }

  String get replyLabel {
    switch (replyType) {
      case 'fixed':
        return 'Fixed Message';
      case 'ai':
        return 'AI Generated';
      default:
        return replyType;
    }
  }
}
