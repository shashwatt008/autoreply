class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profilePic;
  final String plan;
  final String? facebookId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePic,
    required this.plan,
    this.facebookId,
  });

  bool get isPro => plan.toLowerCase() == 'pro';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePic: json['profilePic'] ?? json['profile_pic'],
      plan: json['plan'] ?? 'free',
      facebookId: json['facebookId'] ?? json['facebook_id'],
    );
  }
}
