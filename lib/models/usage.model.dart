class UsageModel {
  UsageModel({
    required this.userId,
    required this.usageLimit,
    required this.usage,
    required this.mediaUsage,
    required this.mediaUsageLimit,
  });

  final String userId;
  final int? usageLimit;
  final int usage;
  final int mediaUsage;
  final int? mediaUsageLimit;

  double? get usageRate =>
      usageLimit != null && usageLimit! > 0 ? usage / usageLimit! : null;

  double? get mediaUsageRate => mediaUsageLimit != null && mediaUsageLimit! > 0
      ? mediaUsage / mediaUsageLimit!
      : null;

  factory UsageModel.fromMap(Map<String, dynamic> data) {
    return UsageModel(
      userId: data['userId'],
      usageLimit: data['usageLimit'],
      usage: data['usage'],
      mediaUsage: data['mediaUsage'],
      mediaUsageLimit: data['mediaUsageLimit'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'usageLimit': usageLimit,
      'usage': usage,
      'mediaUsage': mediaUsage,
      'mediaUsageLimit': mediaUsageLimit,
    };
  }
}

class UsageLimitModel {
  final String userId;
  final int? usageLimit;
  final int? mediaUsageLimit;

  UsageLimitModel({
    required this.userId,
    required this.usageLimit,
    required this.mediaUsageLimit,
  });

  factory UsageLimitModel.fromMap(Map<String, dynamic> data) {
    return UsageLimitModel(
      userId: data['userId'],
      usageLimit: data['usageLimit'],
      mediaUsageLimit: data['mediaUsageLimit'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'usageLimit': usageLimit,
      'mediaUsageLimit': mediaUsageLimit,
    };
  }
}
