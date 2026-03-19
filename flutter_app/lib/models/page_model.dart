class PageModel {
  final String id;
  final String name;
  final String? profilePic;
  final String? accessToken;
  final int? followerCount;
  final String? category;

  PageModel({
    required this.id,
    required this.name,
    this.profilePic,
    this.accessToken,
    this.followerCount,
    this.category,
  });

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      profilePic: json['profilePic'] ?? json['profile_pic'] ?? json['picture']?['data']?['url'],
      accessToken: json['access_token'] ?? json['accessToken'],
      followerCount: json['follower_count'] ?? json['followerCount'] ?? json['followers_count'],
      category: json['category'],
    );
  }
}
