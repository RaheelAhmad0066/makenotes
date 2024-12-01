import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:makernote/models/promo_code.model.dart';
import 'package:makernote/models/reward.model.dart';

class PromoCodeService {
  Future<RewardModel> redeemPromoCode(String code) async {
    // call cloud function and return reward
    try {
      HttpsCallable callable =
          FirebaseFunctions.instanceFor(region: 'asia-east2')
              .httpsCallable('redeemPromoCode');
      final response = await callable.call({'code': code});
      return RewardModel.fromMap(Map<String, dynamic>.from(response.data));
    } on FirebaseFunctionsException catch (e, _) {
      debugPrint('Error redeeming promo code: ${e.message} [${e.code}]');
      rethrow;
    } catch (e) {
      debugPrint('Error redeeming promo code: $e');
      rethrow;
    }
  }

  Future<PromoCodeModel> generateCode({
    String? customCode,
    int? maxRedemptions = 1,
    required int usageLimit,
    required int mediaUsageLimit,
    int expiryDuration = 1 * 24 * 60 * 60,
  }) async {
    // call cloud function and return promo code
    try {
      HttpsCallable callable =
          FirebaseFunctions.instanceFor(region: 'asia-east2')
              .httpsCallable('generatePromoCode');
      final response = await callable.call({
        if (customCode != null) 'code': customCode,
        if (customCode != null) 'maxRedemptions': maxRedemptions,
        'usageLimit': usageLimit,
        'mediaUsageLimit': mediaUsageLimit,
        'expiry': expiryDuration,
      });
      return PromoCodeModel.fromMap(Map<String, dynamic>.from(response.data));
    } on FirebaseFunctionsException catch (e, _) {
      debugPrint('Error generating promo code: ${e.message} [${e.code}]');
      rethrow;
    } catch (e) {
      debugPrint('Error generating promo code: $e');
      rethrow;
    }
  }
}
