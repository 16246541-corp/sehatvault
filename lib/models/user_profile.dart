import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 40)
class UserProfile extends HiveObject {
  @HiveField(0)
  String? displayName;

  @HiveField(1)
  String? sex; // 'male', 'female', 'unspecified'

  @HiveField(2)
  DateTime? dateOfBirth;

  @HiveField(3)
  DateTime createdAt;

  UserProfile({
    this.displayName,
    this.sex = 'unspecified',
    this.dateOfBirth,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }
}
