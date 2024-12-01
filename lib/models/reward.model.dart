class RewardModel {
  RewardModel({
    required this.referencingCode,
    required this.usageLimit,
    required this.mediaUsageLimit,
  });

  final String referencingCode;
  final int usageLimit;
  final int mediaUsageLimit;

  factory RewardModel.fromMap(Map<String, dynamic> json) => RewardModel(
        referencingCode: json['referencingCode'],
        usageLimit: json['usageLimit'],
        mediaUsageLimit: json['mediaUsageLimit'],
      );

  Map<String, dynamic> toMap() => {
        'referencingCode': referencingCode,
        'usageLimit': usageLimit,
        'mediaUsageLimit': mediaUsageLimit,
      };
}
