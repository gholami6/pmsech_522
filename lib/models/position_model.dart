import 'package:hive/hive.dart';

part 'position_model.g.dart';

@HiveType(typeId: 10)
enum RoleType {
  @HiveField(0)
  manager,

  @HiveField(1)
  supervisor,

  @HiveField(2)
  industrialExpert,

  @HiveField(3)
  mechanicalExpert,

  @HiveField(4)
  electricalExpert,

  @HiveField(5)
  designExpert,

  @HiveField(6)
  processExpert,

  @HiveField(7)
  director;

  String get title {
    switch (this) {
      case RoleType.manager:
        return 'مدیر';
      case RoleType.supervisor:
        return 'سرپرست';
      case RoleType.industrialExpert:
        return 'کارشناس صنایع';
      case RoleType.mechanicalExpert:
        return 'کارشناس مکانیک';
      case RoleType.electricalExpert:
        return 'کارشناس برق';
      case RoleType.designExpert:
        return 'کارشناس طراحی';
      case RoleType.processExpert:
        return 'کارشناس پروسس';
      case RoleType.director:
        return 'رئیس';
    }
  }
}

@HiveType(typeId: 11)
enum StakeholderType {
  @HiveField(0)
  employer,

  @HiveField(1)
  consultant,

  @HiveField(2)
  contractor;

  String get title {
    switch (this) {
      case StakeholderType.employer:
        return 'کارفرما';
      case StakeholderType.consultant:
        return 'مشاور';
      case StakeholderType.contractor:
        return 'پیمانکار';
    }
  }
}

@HiveType(typeId: 12)
class PositionModel {
  @HiveField(0)
  final StakeholderType stakeholderType;

  @HiveField(1)
  final RoleType roleType;

  PositionModel({
    required this.stakeholderType,
    required this.roleType,
  });

  String get title => '${roleType.title} ${stakeholderType.title}';

  factory PositionModel.fromTitle(String title) {
    final parts = title.trim().split(' ').where((p) => p.isNotEmpty).toList();

    // حالت‌های مختلف فرمت position
    String roleTitle;
    String stakeholderTitle;

    if (parts.length == 1) {
      // فرمت تک‌کلمه‌ای مانند: "مدیر" → پیش‌فرض ذینفع: کارفرما
      roleTitle = parts[0];
      stakeholderTitle = 'کارفرما';
    } else if (parts.length == 2) {
      // فرمت استاندارد: "کارشناس کارفرما"
      roleTitle = parts[0];
      stakeholderTitle = parts[1];
    } else if (parts.length == 3) {
      // فرمت گسترده: "کارشناس پروسس کارفرما"
      roleTitle = '${parts[0]} ${parts[1]}'; // "کارشناس پروسس"
      stakeholderTitle = parts[2]; // "کارفرما"
    } else {
      throw Exception('فرمت عنوان پوزیشن نامعتبر است: $title');
    }

    final roleType = RoleType.values.firstWhere(
      (type) => type.title == roleTitle,
      orElse: () => throw Exception('نوع نقش نامعتبر است: $roleTitle'),
    );

    final stakeholderType = StakeholderType.values.firstWhere(
      (type) => type.title == stakeholderTitle,
      orElse: () => throw Exception('نوع ذینفع نامعتبر است: $stakeholderTitle'),
    );

    return PositionModel(
      stakeholderType: stakeholderType,
      roleType: roleType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PositionModel &&
        other.stakeholderType == stakeholderType &&
        other.roleType == roleType;
  }

  @override
  int get hashCode => stakeholderType.hashCode ^ roleType.hashCode;
}
