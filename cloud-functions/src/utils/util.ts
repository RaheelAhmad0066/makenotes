
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";

type AccessRight = "read" | "write" | "delete";

export async function isItemAccessible(userId: string, itemId: string, authUid: string, right: AccessRight = "read"): Promise<boolean> {
  // Check if the user has direct accessibility to the item
  const directAccess = await admin.firestore()
    .collection("users").doc(userId)
    .collection("item").doc(itemId)
    .collection("accessibility").doc(authUid)
    .get();

  if (directAccess.exists && (directAccess.data()?.["rights"] as AccessRight[])?.includes(right)) {
    return true;
  }

  // If not directly accessible, check for inherited accessibility from parent folders
  let currentItem = await admin.firestore()
    .collection("users").doc(userId)
    .collection("item").doc(itemId)
    .get();

  // Loop through parent folders to check for inherited accessibility
  while (currentItem.exists && currentItem.data()?.parentId) {
    const parentItem = await admin.firestore()
      .collection("users").doc(userId)
      .collection("item").doc(currentItem.data()?.parentId)
      .get();

    const parentAccess = await parentItem.ref.collection("accessibility").doc(authUid).get();
    if (parentAccess.exists && (parentAccess.data()?.["rights"] as AccessRight[])?.includes(right)) {
      return true;
    }

    currentItem = parentItem; // Move up to the next parent folder
  }

  return false;
}

export async function grantAccessRight(ownerId: string, itemId: string, userId: string, rights: AccessRight[]) {
  const db = admin.firestore();

  // Check if the item exists in the user's item collection
  const itemSnapshot = await db.collection("users").doc(ownerId).collection("item").doc(itemId).get();

  if (!itemSnapshot.exists) {
    throw new Error("Item does not exist.");
  }

  // Add the user to the accessibility subcollection
  await itemSnapshot.ref.collection("accessibility").doc(userId).set({
    userId: userId,
    rights: FieldValue.arrayUnion(...rights),
    itemId: itemSnapshot.id,
  }, { merge: true });
}

export async function revokeAccessRight(ownerId: string, itemId: string, userId: string | undefined) {
  const db = admin.firestore();

  // Check if the item exists in the user's item collection
  const itemSnapshot = await db.collection("users").doc(ownerId).collection("item").doc(itemId).get();

  if (!itemSnapshot.exists) {
    throw new Error("Item does not exist.");
  }

  if (userId !== undefined) {
    // remove accessibility of the user
    await itemSnapshot.ref.collection("accessibility").doc(userId).delete();

    // remove user's accessible of the item
    const accessibleSnapshot = await db.collection("users").doc(userId).collection("accessibles")
      .where("ownerId", "==", ownerId)
      .where("itemId", "==", itemId)
      .get();

    if (!accessibleSnapshot.empty) {
      await accessibleSnapshot.docs[0].ref.delete();
    }
  } else {
    // remove accessibility of all users
    const accessibilitySnapshot = await itemSnapshot.ref.collection("accessibility").get();
    accessibilitySnapshot.docs.forEach((doc) => {
      // remove accessible of the item of the user
      db.collection("users").doc(doc.id).collection("accessibles")
        .where("ownerId", "==", ownerId)
        .where("itemId", "==", itemId)
        .get()
        .then((snapshot) => {
          if (!snapshot.empty) {
            snapshot.docs[0].ref.delete();
          }
        });

      doc.ref.delete();
    });
  }
}

export async function addAccessible(userId: string, ownerId: string, itemId: string, rights: AccessRight[]) {
  const db = admin.firestore();

  const accessibleSnapshot = await db.collection("users").doc(userId).collection("accessibles")
    .where("ownerId", "==", ownerId)
    .where("itemId", "==", itemId)
    .get();

  if (!accessibleSnapshot.empty) {
    // If it exists, update the rights
    await accessibleSnapshot.docs[0].ref.set({
      rights: rights,
    }, { merge: true });
  } else {
    // If it does not exist, create a new accessible
    await db.collection("users").doc(userId).collection("accessibles").add({
      rights: rights,
      ownerId: ownerId,
      itemId: itemId,
    });
  }
}

export async function deleteSubcollection(documentRef: admin.firestore.DocumentReference, subcollectionName: string) {
  const subcollectionRef = documentRef.collection(subcollectionName);
  const snapshot = await subcollectionRef.get();

  if (snapshot.empty) {
    return;
  }

  const batch = admin.firestore().batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();

  // If there are more documents in the subcollection, recursively delete them
  if (snapshot.size >= 500) {
    await deleteSubcollection(documentRef, subcollectionName);
  }
}

export async function updateAccessibilityOfAllChildItem(userId: string, itemId: string, rights: any) {
  const db = admin.firestore();
  const itemsSnapshot = await db.collection("users").doc(userId).collection("item")
    .where("parentId", "==", itemId)
    .get();
  if (!itemsSnapshot.empty) {
    for (const item of itemsSnapshot.docs) {
      const itemRef = item.ref;
      await itemRef.collection("accessibility").doc(userId).set({
        userId: userId,
        rights: rights,
      }, { merge: true });
      await updateAccessibilityOfAllChildItem(userId, item.id, rights);
    }
  }
}
