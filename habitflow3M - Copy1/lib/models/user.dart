import 'package:isar/isar.dart';

part 'user.g.dart';

@Collection()
class UserModel {
  Id id = Isar.autoIncrement;

  late String name;
  late String email;
  late String password;
  String? bio;
  String? profileImageUrl;

  UserModel();

  UserModel.create({
    required this.name,
    required this.email,
    required this.password,
    this.bio,
    this.profileImageUrl,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? password,
    String? bio,
    String? profileImageUrl,
  }) {
    return UserModel.create(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    )..id = this.id;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'password': password,
    'bio': bio,
    'profileImageUrl': profileImageUrl,
  };
}
