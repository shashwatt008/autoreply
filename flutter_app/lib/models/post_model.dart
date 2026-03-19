class PostModel {
  final String id;
  final String? message;
  final String? caption;
  final String? imageUrl;
  final String? mediaUrl;
  final String? mediaType;
  final String? createdTime;
  final String? permalink;

  PostModel({
    required this.id,
    this.message,
    this.caption,
    this.imageUrl,
    this.mediaUrl,
    this.mediaType,
    this.createdTime,
    this.permalink,
  });

  String get displayText => message ?? caption ?? 'No caption';

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? json['_id'] ?? '',
      message: json['message'],
      caption: json['caption'],
      imageUrl: json['full_picture'] ?? json['imageUrl'],
      mediaUrl: json['media_url'] ?? json['mediaUrl'],
      mediaType: json['media_type'] ?? json['mediaType'],
      createdTime: json['created_time'] ?? json['createdTime'] ?? json['timestamp'],
      permalink: json['permalink'],
    );
  }
}
