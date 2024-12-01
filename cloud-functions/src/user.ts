
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { User } from "./types/user";
import { Usage, UsageLimit } from "./types/usage";

export const deleteUser = onCall({ region: "asia-east2" }, async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to access this resource.");
  }

  const userId = request.auth.uid;

  // Get the user ref
  const userRef = admin.firestore().collection("users").doc(userId);

  // Delete the user
  await userRef.delete();
});

// / get user's usage
export const getUsage = onCall({ region: "asia-east2" }, async (request): Promise<Usage> => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to access this resource.");
  }

  const userId: string = request.data.userId ?? request.auth.uid;

  const userDoc = await admin.firestore()
    .collection("users").doc(userId)
    .get();

  const user = userDoc.data() as User;

  // add a default usage limit if the user does not have one
  if (!user.usage?.usageLimit) {
    const usageLimit: UsageLimit = {
      userId: userId,
      usageLimit: 100,
      // 5 GB
      mediaUsageLimit: 5 * 1024 * 1024 * 1024,
      mediaUsage: 0,
    };
    await userDoc.ref.update({
      usage: usageLimit,
    });
    user.usage = usageLimit;
  }

  const limit = user.usage.usageLimit;

  // count the number of items
  const itemsCount = await admin.firestore()
    .collection("users").doc(userId)
    .collection("item")
    .where("isTrashBin", "==", false)
    .count()
    .get();

  // return a usage object
  return {
    userId: userId,
    usageLimit: limit,
    usage: itemsCount.data().count,
    mediaUsage: user.usage.mediaUsage ?? 0,
    mediaUsageLimit: user.usage.mediaUsageLimit,
  };
});
