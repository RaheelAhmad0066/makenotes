
import { firestore } from "firebase-admin";

enum NoteType {
    template,
    exercise,
    marking,
    solution,
}

export type NoteReferenceModel = {
    noteId: string;
    overlayType: number;
};

enum MCOption {
    A,
    B,
    C,
    D,
}

export type NoteMCModel = {
    correctAnswer?: MCOption;
    createdAt: firestore.Timestamp;
    updatedAt: firestore.Timestamp;
};

export type MarkingModel = {
    markingId: string;
    pageId: string;
    yPostion: number;
    name: string;
    score: number;
}

export type Note = {
    id?: string;
    ownerId: string;
    name: string;
    type: string;
    parentId?: string;
    previousParentId?: string;
    createdAt: firestore.Timestamp;
    updatedAt: firestore.Timestamp;
    isTrashBin: boolean;
    isVisible: boolean;
    overlayOn?: NoteReferenceModel;
    overlayedBy: NoteReferenceModel[];
    noteType: NoteType;
    multipleChoices?: NoteMCModel[];
    markings?: MarkingModel[];
    createdBy: string;
    locked: boolean;
    lockedAt?: firestore.Timestamp;
    hideExplanation: boolean;
};
