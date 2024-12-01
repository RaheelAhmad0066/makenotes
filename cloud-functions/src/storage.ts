
import { onObjectDeleted, onObjectFinalized } from "firebase-functions/v2/storage";
import * as admin from "firebase-admin";
import { User } from "./types/user";

export const updateUserMediaUsage = onObjectFinalized({
  region: "asia-east2",
  bucket: "makernote-b5e60.appspot.com",
}, async (event) => {
  // update user's media usage
  const filePath = event.data.name;
  const userId = filePath.split("/")[0];
  const mediaUsage = event.data.size;
  const userRef = admin.firestore().collection("users").doc(userId);
  try {
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return;
    }

    const user = userDoc.data() as User;
    const newMediaUsage = Number(user.usage?.mediaUsage ?? 0 + mediaUsage);
    userRef.update({
      usage: {
        ...user.usage,
        mediaUsage: newMediaUsage,
      },
    });
  } catch (error) {
    console.error(error);
  }
});

export const deleteUserMediaUsage = onObjectDeleted({
  region: "asia-east2",
  bucket: "makernote-b5e60.appspot.com",
}, async (event) => {
  // update user's media usage
  const filePath = event.data.name;
  const userId = filePath.split("/")[0];
  const mediaUsage = event.data.size;
  const userRef = admin.firestore().collection("users").doc(userId);
  try {
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return;
    }

    const user = userDoc.data() as User;
    const newMediaUsage = Number(user.usage?.mediaUsage ?? 0 - mediaUsage);
    userRef.update({
      usage: {
        ...user.usage,
        mediaUsage: newMediaUsage,
      },
    });
  } catch (error) {
    console.error(error);
  }
});
