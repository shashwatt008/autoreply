class InstagramAccountModel {
  final String id;
  final String name;
  final String? username;
  final String? profilePic;
  final int? followerCount;

  InstagramAccountModel({
    required this.id,
    required this.name,
    this.username,
    this.profilePic,
    this.followerCount,
  });

  factory InstagramAccountModel.fromJson(Map<String, dynamic> json) {
    return InstagramAccountModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? json['username'] ?? '',
      username: json['username'],
      profilePic: json['profilePic'] ?? json['profile_pic'] ?? json['profile_picture_url'],
      followerCount: json['follower_count'] ?? json['followerCount'] ?? json['followers_count'],
    );
  }
}
