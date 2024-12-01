
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { PromoCode } from "./types/promo_code";
import { Timestamp } from "firebase-admin/firestore";
import { UsageLimit } from "./types/usage";

export const redeemPromoCode = onCall({ region: "asia-east2" }, async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to access this resource.");
  }

  const userId = request.auth.uid;
  const code = request.data.code;

  // Get the user ref
  const userRef = admin.firestore().collection("users").doc(userId);

  // Get the promo code ref by token
  const promoCodeQuery = admin.firestore().collection("promoCodes").where("code", "==", code).limit(1);

  const promoCodeSnapshot = await promoCodeQuery.get();

  if (promoCodeSnapshot.empty) {
    throw new HttpsError("not-found", "Promo code not found.");
  }

  const promoCodeDoc = promoCodeSnapshot.docs[0];

  const promoCode = promoCodeDoc.data() as PromoCode;

  if (promoCode.redeemedBy.includes(userId) || (!!promoCode.maxRedemptions && promoCode.redeemedBy.length >= promoCode.maxRedemptions)) {
    throw new HttpsError("already-exists", "Promo code has already been redeemed.");
  }

  const now = Timestamp.now();

  if (promoCode.expiresAt.toMillis() < now.toMillis()) {
    throw new HttpsError("deadline-exceeded", "Promo code has expired.");
  }

  const usage = (await userRef.get().then((doc) => doc.data()?.usage)) as UsageLimit | undefined;

  if (!usage) {
    throw new HttpsError("not-found", "User not found.");
  }

  // Add the promo code value to the user
  await userRef.update({
    usage: {
      ...usage,
      usageLimit: usage.usageLimit == null ? null : usage.usageLimit + promoCode.reward.usageLimit,
      mediaUsageLimit: usage.mediaUsageLimit == null ? null : usage.mediaUsageLimit + promoCode.reward.mediaUsageLimit,
    },
    rewardHistory: admin.firestore.FieldValue.arrayUnion(promoCode.reward),
  });

  // Add the user to the promo code
  await promoCodeDoc.ref.update({
    redeemedBy: admin.firestore.FieldValue.arrayUnion(userId),
  });

  return promoCode.reward;
});

// generate a promo code
export const generatePromoCode = onCall({ region: "asia-east2" }, async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to access this resource.");
  }

  const userId = request.auth.uid;
  const customCode = request.data.code as string | undefined;
  const maxRedemptions = request.data.maxRedemptions as string | undefined;
  const usageLimit = Number(request.data.usageLimit);
  const mediaUsageLimit = Number(request.data.mediaUsageLimit);
  const expiryDuration = Number(request.data.expiry); // in seconds

  // Get the user ref
  const userRef = admin.firestore().collection("users").doc(userId);

  const userDoc = await userRef.get();

  const user = userDoc.data();

  if (user?.email != "tackledinnovation@gmail.com") {
    throw new HttpsError("permission-denied", "User must be an admin to access this resource.");
  }

  // Generate a random unique 6 digit alphanumeric code if no custom code is provided
  let code: string | null = null;
  let retryCount = 0;

  if (customCode) {
    // Check if the code already exists
    const promoCodeQuery = admin.firestore().collection("promoCodes").where("code", "==", customCode).limit(1);
    const promoCodeSnapshot = await promoCodeQuery.get();

    if (!promoCodeSnapshot.empty) {
      throw new HttpsError("already-exists", "Promo code already exists.");
    }

    code = customCode;
  } else {
    while (retryCount < 10) {
      code = Math.random().toString(36).substring(2, 8).toUpperCase();

      // Check if the code already exists
      const promoCodeQuery = admin.firestore().collection("promoCodes").where("code", "==", code).limit(1);
      const promoCodeSnapshot = await promoCodeQuery.get();

      if (promoCodeSnapshot.empty) {
        break;
      }

      retryCount++;
    }
  }

  if (retryCount === 10 || code === null) {
    throw new Error("Failed to generate a unique promo code.");
  }

  // Create the promo code
  const promoCode: PromoCode = {
    code: code,
    redeemedBy: [],
    maxRedemptions: maxRedemptions ? Number(maxRedemptions) : null,
    reward: {
      referencingCode: code,
      usageLimit: usageLimit,
      mediaUsageLimit: mediaUsageLimit,
    },
    expiresAt: Timestamp.fromMillis(Date.now() + expiryDuration * 1000),
    createdAt: Timestamp.now(),
  };

  await admin.firestore().collection("promoCodes").add(promoCode);

  return promoCode;
});
