import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:makernote/models/reward.model.dart';
import 'package:makernote/utils/helpers/serialization.helper.dart';

class PromoCodeModel {
  String code;
  List<String> redeemedBy;
  int? maxRedemptions;
  RewardModel reward;
  Timestamp expiresAt;
  Timestamp createdAt;

  PromoCodeModel({
    required this.code,
    required this.redeemedBy,
    required this.maxRedemptions,
    required this.reward,
    required this.expiresAt,
    required this.createdAt,
  });

  factory PromoCodeModel.fromMap(Map<String, dynamic> json) {
    return PromoCodeModel(
      code: json['code'],
      redeemedBy: List<String>.from(json['redeemedBy']),
      maxRedemptions: json['maxRedemptions'],
      reward: RewardModel.fromMap(Map<String, dynamic>.from(json['reward'])),
      expiresAt: json['expiresAt'] is Map
          ? parseFirestoreTimestamp(
              Map<String, dynamic>.from(json['expiresAt']))
          : json['expiresAt'],
      createdAt: json['createdAt'] is Map
          ? parseFirestoreTimestamp(
              Map<String, dynamic>.from(json['createdAt']))
          : json['createdAt'],
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'redeemedBy': redeemedBy,
        'maxRedemptions': maxRedemptions,
        'reward': reward.toMap(),
        'expiresAt': expiresAt,
        'createdAt': createdAt,
      };
}

/*

export type PromoCode = {
    code: string;
    redeemedBy: string[];
    maxRedemptions: number | null | undefined;
    reward: Reward;
    expiresAt: Date;
    createdAt: Date;
}

*/