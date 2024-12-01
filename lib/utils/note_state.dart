import 'package:makernote/models/note_model.dart';
import 'package:makernote/services/item/accessibility.service.dart';

enum NoteScreenState {
  editingTemplate,
  viewingTemplate,
  doingExercise,
  submittedExercise,
  viewingExercise,
  pendingExercise,
  editingMarking,
  startedMarking,
  finishedMarking,
}

NoteScreenState getNoteStackState(NoteModelStack noteStack) {
  final accessibilityService = AccessibilityService();
  final exerciseNote = noteStack.getNoteByNoteType(NoteType.exercise);
  final markingNote = noteStack.getNoteByNoteType(NoteType.marking);
  bool isOwner =
      accessibilityService.currentUserId == noteStack.template.ownerId;

  // viewing template
  if (noteStack.overlays.isEmpty && !isOwner) {
    return NoteScreenState.viewingTemplate;
  }

  // editing template
  if (noteStack.overlays.isEmpty && isOwner) {
    return NoteScreenState.editingTemplate;
  }

  // validate note stack for exercise
  if (exerciseNote == null) {
    throw Exception(
        'Invalid note stack: exercise note not found in note stack');
  }

  bool isExerciseCreator = noteStack.hasFocus &&
      noteStack.focusedNote!.noteType == NoteType.exercise &&
      accessibilityService.currentUserId == exerciseNote.createdBy;

  // viewing exercise
  if (isExerciseCreator && markingNote?.locked == true) {
    return NoteScreenState.viewingExercise;
  }

  // doing exercise
  if (isExerciseCreator && !exerciseNote.locked) {
    return NoteScreenState.doingExercise;
  }

  // submitted exercise
  if (isExerciseCreator && exerciseNote.locked) {
    return NoteScreenState.submittedExercise;
  }

  // pending exercise
  if (!isExerciseCreator &&
      noteStack.hasNoteType(NoteType.exercise) &&
      !noteStack.hasNoteType(NoteType.marking)) {
    return NoteScreenState.pendingExercise;
  }

  // validate note stack for marking
  if (markingNote == null) {
    throw Exception('Invalid note stack: marking note not found in note stack');
  }

  bool isMarkingCreator = noteStack.hasFocus &&
      noteStack.focusedNote!.noteType == NoteType.marking &&
      accessibilityService.currentUserId == markingNote.createdBy;

  // editing marking
  if (isMarkingCreator && !markingNote.locked) {
    return NoteScreenState.editingMarking;
  }

  // started marking
  if (isMarkingCreator && markingNote.locked && markingNote.lockedAt == null) {
    return NoteScreenState.startedMarking;
  }

  // finished marking
  if (isMarkingCreator && markingNote.locked && markingNote.lockedAt != null) {
    return NoteScreenState.finishedMarking;
  }

  throw Exception('Invalid note stack: unknown state');
}
