
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as util from "./utils/util";
import { Timestamp } from "firebase-admin/firestore";
import { asyncFilter } from "./utils/list.util";
import { deleteUserItemFolder } from "./utils/cloud_store.util";

// / Return a item's data if the user has access to it
export const getItem = onCall({ region: "asia-east2" }, async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to access this resource.");
  }

  const userId: string = request.data.userId;
  const itemId: string = request.data.itemId;

  // Check if the item is accessible to read
  const accessible = request.auth.uid === userId || await util.isItemAccessible(userId, itemId, request.auth.uid, "read");

  if (accessible) {
    // Fetch and return the item
    const itemDoc = await admin.firestore()
      .collection("users").doc(userId)
      .collection("item").doc(itemId)
      .get();

    return itemDoc.data();
  } else {
    throw new HttpsError("permission-denied", "User does not have access to the requested item.");
  }
});

// Return a list of items that the user has access to
export const getItems = onCall({ region: "asia-east2" }, async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to access this resource.");
  }

  const authUserId: string = request.auth.uid;
  const ownerId: string = request.data.ownerId;
  const parentId: string | null = request.data.parentId;

  if (parentId === null) {
    // fetch all folders and notes with two separate queries
    const foldersSnapshot = await admin.firestore()
      .collection("users").doc(ownerId)
      .collection("item")
      .where("parentId", "==", null)
      .where("type", "==", "folder")
      .get();

    const notesSnapshot = await admin.firestore()
      .collection("users").doc(ownerId)
      .collection("item")
      .where("parentId", "==", null)
      .where("type", "==", "note")
      .where("noteType", "in", [0, 1])
      .where("createdBy", "in", [authUserId, ownerId])
      .get();

    // merge the two lists
    const mergedItemDocs = [...foldersSnapshot.docs, ...notesSnapshot.docs];

    // Filter out items that the user does not have access to
    const items = await asyncFilter(mergedItemDocs, async (doc) => {
      const accessible = authUserId === ownerId || await util.isItemAccessible(ownerId, doc.id, authUserId, "read");
      console.log(`Item ${doc.id} is accessible: ${accessible}`);
      return accessible;
    });

    return items.map((doc) => ({ ...doc.data(), id: doc.id }));
  } else {
    // Check if the parent folder is accessible to read
    const accessible = authUserId === ownerId || await util.isItemAccessible(ownerId, parentId, authUserId, "read");

    if (accessible) {
      // fetch all folders and notes with two separate queries
      const foldersSnapshot = await admin.firestore()
        .collection("users").doc(ownerId)
        .collection("item")
        .where("parentId", "==", parentId)
        .where("type", "==", "folder")
        .get();

      const notesSnapshot = await admin.firestore()
        .collection("users").doc(ownerId)
        .collection("item")
        .where("parentId", "==", parentId)
        .where("type", "==", "note")
        .where("noteType", "in", [0, 1])
        .where("createdBy", "in", [authUserId, ownerId])
        .get();

      // merge the two lists
      const mergedItemDocs = [...foldersSnapshot.docs, ...notesSnapshot.docs];

      return mergedItemDocs.map((doc) => ({ ...doc.data(), id: doc.id }));
    } else {
      throw new HttpsError("permission-denied", "User does not have access to the requested folder.");
    }
  }
});

export const applyAccessRight = onCall({ region: "asia-east2" }, async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const token = request.data.token;
  const userId = request.auth.uid;
  const db = admin.firestore();

  // Validate the token
  const tokenSnapshot = await db.collectionGroup("sharedTokens")
    .where("token", "==", token)
    .where("expiresAt", ">", Timestamp.now())
    .get();

  if (tokenSnapshot.empty) {
    throw new HttpsError("not-found", "Token does not exist or has expired.");
  }

  // Token is valid, proceed with updating access rights
  const tokenDoc = tokenSnapshot.docs[0];
  const itemRef = tokenDoc.ref.parent.parent;
  const tokenModel = tokenDoc.data();

  if (!itemRef) {
    throw new HttpsError("not-found", "Item does not exist.");
  }
  const ownerId = itemRef.parent.parent?.id;

  if (!ownerId) {
    throw new HttpsError("not-found", "Owner does not exist.");
  }

  try {
    await util.grantAccessRight(
      ownerId,
      itemRef.id,
      userId,
      tokenModel.rights
    );
  } catch (error: any) {
    throw new HttpsError("internal", error.message);
  }

  // Check the accessible with the same [ownerId] and [itemId] already exists
  await util.addAccessible(userId, ownerId, itemRef.id, tokenModel.rights);

  // update accessibility of all items has the [parentId] is the same as [itemId]
  // await updateAccessibilityOfAllChildItem(ownerId, itemId, tokenModel.rights);

  return { success: true };
});

export const grantAccessRight = onCall({ region: "asia-east2" }, async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const userId = request.data.userId ?? request.auth.uid;
  const ownerId = request.data.ownerId;
  const itemId = request.data.itemId;
  const rights = request.data.rights;

  try {
    util.grantAccessRight(
      ownerId,
      itemId,
      userId,
      rights
    );

    return { success: true };
  } catch (error: any) {
    throw new HttpsError("internal", error.message);
  }
});

export const removeAccessRight = onCall({ region: "asia-east2" }, async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const ownerId = request.auth.uid;
  const userId: string | undefined = request.data.userId;
  const itemId = request.data.itemId;

  try {
    await util.revokeAccessRight(ownerId, itemId, userId);
  } catch (error: any) {
    throw new HttpsError("internal", error.message);
  }
});

export const deleteItemWithSubcollections = onCall({ region: "asia-east2" }, async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to access this resource.");
  }

  const userId = request.data.userId;
  const itemId = request.data.itemId;

  // Check if the user has permission to delete the item
  if (request.auth.uid !== userId && !await util.isItemAccessible(userId, itemId, request.auth.uid, "delete")) {
    throw new HttpsError("permission-denied", "User does not have permission to delete this item.");
  }

  const itemRef = admin.firestore()
    .collection("users")
    .doc(userId)
    .collection("item")
    .doc(itemId);

  try {
    // Update overlayedBy field in the parent item
    const itemDoc = await itemRef.get();
    if (!itemDoc.exists) {
      throw new Error(`Item ${itemId} does not exist.`);
    }

    const parentId = itemDoc.data()?.overlayOn.noteId as string;
    const parentItemRef = admin.firestore()
      .collection("users")
      .doc(userId)
      .collection("item")
      .doc(parentId);
    // Remove the item from the parent's overlayedBy list
    await parentItemRef.update({
      overlayedBy: admin.firestore.FieldValue.arrayRemove({
        noteId: itemId,
        ownerId: userId,
      }),
    });

    // Delete all subcollections
    const subcollections = await itemRef.listCollections();
    for (const subcollection of subcollections) {
      await util.deleteSubcollection(itemRef, subcollection.id);
    }
  } catch (error) {
    console.error(`Error deleting subcollections of item ${itemId}: ${error}`);
  }

  try {
    // Delete all related media files
    await deleteUserItemFolder(userId, itemId);
  } catch (error) {
    console.error(`Error deleting media files of item ${itemId}: ${error}`);
  }

  // Finally, delete the main document
  return itemRef.delete();
});
