
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { grantAccessRight, isItemAccessible } from "./utils/util";
import { Timestamp, FieldValue } from "firebase-admin/firestore";
import { Note as NoteModel } from "./types/note";

export const createOverlayNote = onCall({ region: "asia-east2" }, async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to access this resource.");
  }

  const userId = request.auth.uid;
  const ownerId = request.data.ownerId;
  const itemId = request.data.itemId;
  const noteModel = request.data.noteModel;

  // Check if the item is accessible to read
  const accessible = request.auth.uid === userId || await isItemAccessible(ownerId, itemId, userId, "read");

  if (!accessible) {
    throw new HttpsError("permission-denied", "User does not have access to the requested item.");
  } else {
    const targetItemRef = await admin.firestore()
      .collection("users").doc(ownerId)
      .collection("item").doc(itemId);

    const targetItem = await targetItemRef.get();

    noteModel["parentId"] = targetItem.data()?.parentId;
    noteModel["createdAt"] = Timestamp.now();
    noteModel["updatedAt"] = Timestamp.now();
    noteModel["multipleChoices"] = (noteModel["multipleChoices"] as any[]).map((choice) => {
      return {
        ...choice,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      };
    });

    // Create the note
    const newNote = await admin.firestore()
      .collection("users").doc(ownerId)
      .collection("item").add(noteModel);

    console.log(`New note created: ${newNote.id}`);

    // Add a reference of the new note to the item
    targetItemRef.update({
      overlayedBy: FieldValue.arrayUnion({
        noteId: newNote.id,
        ownerId: noteModel.ownerId,
      }),
    });

    // Add access rights to the new note
    if (ownerId != userId) {
      await grantAccessRight(ownerId, newNote.id, userId, ["read", "write", "delete"]);
    }

    return { ...(await newNote.get()).data(), id: newNote.id };
  }
});

type LockMarkingNotesRequest = {
  templateId: string;
}
// lock marking notes
export const lockMarkingNotes = onCall({ region: "asia-east2" }, async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to access this resource.");
  }

  const ownerId = request.auth.uid;
  const { templateId } = request.data as LockMarkingNotesRequest;

  try {
    // get the template note
    const templateNoteRef = admin.firestore()
      .collection("users").doc(ownerId)
      .collection("item").doc(templateId);

    const templateNote = await templateNoteRef.get();

    if (!templateNote.exists) {
      throw new HttpsError("not-found", "Template note not found.");
    }

    // Get all exercise notes
    const exercises = await admin.firestore()
      .collection("users").doc(ownerId)
      .collection("item")
      .where("overlayOn.noteId", "==", templateId)
      .where("noteType", "==", 1)
      .get();

    const batch = admin.firestore().batch();
    for (const exercise of exercises.docs) {
      const exerciseData = exercise.data();

      // check if the exercise note is not locked, then lock it
      if (!exerciseData.locked) {
        batch.update(exercise.ref, {
          locked: true,
          lockedAt: admin.firestore.Timestamp.now(),
        });
      }

      // if the marking note is not found, create a new one
      if (exerciseData.overlayedBy.length === 0) {
        const templateNoteData = templateNote.data();

        if (!templateNoteData) {
          throw new HttpsError("not-found", "Template note not found.");
        }

        const markingNoteData = {
          ...templateNoteData,
          ownerId: ownerId,
          type: "note",
          parentId: exerciseData.parentId,
          createdAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now(),

          overlayOn: {
            noteId: exercise.id,
            ownerId: ownerId,
          },
          overlayedBy: [],
          noteType: 2,
          multipleChoices: templateNoteData.multipleChoices?.map((choice: any) => ({
            ...choice,
            createdAt: admin.firestore.Timestamp.now(),
            updatedAt: admin.firestore.Timestamp.now(),
          })) || null,
          createdBy: ownerId,
          locked: true,
          lockedAt: null,
        };

        const newMarkingNote = await admin.firestore()
          .collection("users").doc(ownerId)
          .collection("item").add(markingNoteData);

        // Add access rights to the new note for the exercise owner
        if (exerciseData.createdBy != ownerId) {
          await grantAccessRight(ownerId, newMarkingNote.id, exerciseData.createdBy, ["read"]);
        }

        batch.update(exercise.ref, {
          overlayedBy: FieldValue.arrayUnion({
            noteId: newMarkingNote.id,
            ownerId: ownerId,
          }),
        });
      } else {
        // get the marking note
        const markingNoteRef = admin.firestore()
          .collection("users").doc(ownerId)
          .collection("item").doc(exerciseData.overlayedBy[0].noteId);

        const markingNote = await markingNoteRef.get();

        if (markingNote.exists && markingNote.data()?.locked != true) {
          // if the marking note is not locked, then lock it
          batch.update(markingNote.ref, {
            locked: true,
          });
        }
      }
    }

    await batch.commit();

    return { success: true };
  } catch (error) {
    console.error("Firestore error:", error);
    throw new HttpsError("internal", "An error occurred while locking marking notes.");
  }
});

type CopyTemplateNoteRequest = {
  templateId: string;
}

export const copyTemplateNote = onCall({ region: "asia-east2" }, async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to access this resource.");
  }

  const ownerId = request.auth.uid;
  const { templateId } = request.data as CopyTemplateNoteRequest;

  try {
    // get the template note
    const templateNoteRef = admin.firestore()
      .collection("users").doc(ownerId)
      .collection("item").doc(templateId);

    const templateNote: NoteModel | undefined = (await templateNoteRef.get()).data() as NoteModel | undefined;

    if (!templateNote) {
      throw new HttpsError("not-found", "Template note not found.");
    }

    if (templateNote.type !== "note") {
      throw new HttpsError("invalid-argument", "The template note must be a note.");
    }

    // Start a Firestore transaction
    return admin.firestore().runTransaction(async (transaction) => {
      // copy the template note
      const newNoteRef = admin.firestore()
        .collection("users").doc(ownerId)
        .collection("item").doc();

      transaction.set(newNoteRef, {
        ...templateNote,
        name: `${templateNote.name} (Copy)`,
        ownerId,
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
        overlayOn: null,
        overlayedBy: [],
        locked: false,
        lockedAt: null,
      });

      // Copy the pages of the template note
      const pages = await admin.firestore()
        .collection("users").doc(ownerId)
        .collection("item").doc(templateId)
        .collection("pages").get();

      for (const page of pages.docs) {
        transaction.set(newNoteRef.collection("pages").doc(page.id), page.data());
      }

      return { ...(await newNoteRef.get()).data(), id: newNoteRef.id };
    });
  } catch (error) {
    console.error("Firestore error:", error);
    throw new HttpsError("internal", "An error occurred while copying the template note.");
  }
});
