import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:makernote/models/item_model.dart';
import 'package:makernote/models/note_mc.model.dart';
import 'package:makernote/plugin/digit_recognition/marking_model.dart';

import '../utils/helpers/serialization.helper.dart';

enum NoteType {
  template,
  exercise,
  marking,
  solution,
}

class NoteModel extends ItemModel {
  final NoteReferenceModel? overlayOn; // overlaying note reference
  final List<NoteReferenceModel> overlayedBy; // overlayed note reference
  final NoteType noteType;

  final List<NoteMCModel>? multipleChoices;
  List<MarkingModel>? markings;

  final String createdBy;
  bool locked;
  Timestamp? lockedAt;
  bool hideExplanation;

  NoteModel({
    super.id,
    required super.ownerId,
    required super.name,
    super.parentId,
    super.previousParentId,
    required super.createdAt,
    required super.updatedAt,
    super.isVisible = true,
    this.overlayOn,
    this.overlayedBy = const [],
    this.noteType = NoteType.template,
    this.multipleChoices,
    this.markings = const <MarkingModel>[],
    required this.createdBy,
    this.locked = false,
    this.lockedAt,
    this.hideExplanation = false,
  }) : super(
          type: ItemType.note,
        );

  void setHideExplanation(bool hideExplanation) {
    // if (this.hideExplanation != hideExplanation) {
    this.hideExplanation = hideExplanation;
    notifyListeners();
    // }
  }

  void setLocked(bool locked, {Timestamp? lockedAt}) {
    // if (this.locked != locked || this.lockedAt != lockedAt) {
    this.locked = locked;
    this.lockedAt = lockedAt;
    notifyListeners();
    // }
  }

  void setMarkings(List<MarkingModel> markings) {
    // if (this.markings != markings) {
    this.markings = markings;
    notifyListeners();
    // }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'overlayOn': overlayOn?.toMap(),
      'overlayedBy': overlayedBy.map((e) => e.toMap()).toList(),
      'noteType': noteType.index,
      'multipleChoices': multipleChoices?.map((e) => e.toMap()).toList(),
      'markings': markings?.map((e) => e.toMap()).toList(),
      'createdBy': createdBy,
      'locked': locked,
      'lockedAt': lockedAt,
      'hideExplanation': hideExplanation,
    };
  }

  static NoteModel fromMap(Map<String, dynamic> map) {
    ItemModel item = ItemModel.fromMap(map);

    return NoteModel(
      id: item.id,
      ownerId: item.ownerId,
      name: item.name,
      parentId: item.parentId,
      previousParentId: item.previousParentId,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      isVisible: item.isVisible,
      overlayOn: map['overlayOn'] != null
          ? NoteReferenceModel.fromMap(
              Map<String, dynamic>.from(map['overlayOn']))
          : null,
      overlayedBy: (map['overlayedBy'] as List<dynamic>?)
              ?.map((e) =>
                  NoteReferenceModel.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      noteType: map['noteType'] == null
          ? NoteType.template
          : NoteType.values[map['noteType']],
      multipleChoices: (map['multipleChoices'] as List<dynamic>?)
          ?.map((e) => NoteMCModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      markings: (map['markings'] as List<dynamic>?)
              ?.map((e) => MarkingModel.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      createdBy: map['createdBy'],
      locked: map['locked'] ?? false,
      lockedAt: map['lockedAt'] is Map
          ? parseFirestoreTimestamp(Map<String, dynamic>.from(map['lockedAt']))
          : map['lockedAt'],
      hideExplanation: map['hideExplanation'] ?? false,
    );
  }

  static NoteModel fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Document data was null');
    }

    data['id'] = doc.id;
    return fromMap(data);
  }

  NoteReferenceModel toReference() {
    return NoteReferenceModel(
      noteId: id!,
      ownerId: ownerId,
    );
  }

  // compare the note with another note by selected fields
  // fields:
  // - name
  // - noteType
  // - length of multipleChoices
  // - locked
  // - lockedAt
  // - hideExplanation
  bool compare(NoteModel other) {
    return name == other.name &&
        noteType == other.noteType &&
        multipleChoices?.length == other.multipleChoices?.length &&
        markings?.length == other.markings?.length &&
        locked == other.locked &&
        lockedAt == other.lockedAt &&
        hideExplanation == other.hideExplanation;
  }

  @override
  String toString() {
    return 'NoteModel(id: $id, ownerId: $ownerId, name: $name)';
  }
}

class NoteReferenceModel {
  final String noteId;
  final String ownerId;

  NoteReferenceModel({
    required this.noteId,
    required this.ownerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'ownerId': ownerId,
    };
  }

  factory NoteReferenceModel.fromMap(Map<String, dynamic> map) {
    return NoteReferenceModel(
      noteId: map['noteId'],
      ownerId: map['ownerId'],
    );
  }

  factory NoteReferenceModel.fromNoteModel(NoteModel note) {
    return NoteReferenceModel(
      noteId: note.id!,
      ownerId: note.ownerId,
    );
  }
}

class NoteModelStack extends ChangeNotifier {
  NoteModelStack({
    required NoteModel template,
    List<NoteModel>? overlays,
  }) {
    _template = template;
    this.overlays = overlays ?? <NoteModel>[].toList(growable: true);
    // focus the template if overlays are empty
    if (this.overlays.isEmpty) {
      _focusedNote = template;
    } else {
      // focus the last overlay
      _focusedNote = this.overlays.last;
    }
  }

  @override
  void dispose() {
    overlays.clear();
    _focusedNote?.dispose();
    super.dispose();
  }

  NoteModel get template => _template;
  set template(NoteModel value) {
    _template = value;
    notifyListeners();
  }

  late final List<NoteModel> overlays;

  late NoteModel _template;

  List<NoteModel> get allNotes => [
        template,
        ...overlays,
      ];
  List<NoteModel> get unfocusedNotes => [
        if (focusedNote != template) template,
        ...overlays.where((element) => element != focusedNote),
      ];

  /// The focused note is the note that is currently being edited
  NoteModel? get focusedNote => _focusedNote;
  NoteModel? _focusedNote;

  bool get hasFocus => _focusedNote != null;

  NoteModelStack mergeStack(NoteModelStack stack) {
    if (stack.template.id != template.id) return this;

    overlays.addAll(stack.overlays);

    if (stack.focusedNote != null) {
      focusOverlay(stack.focusedNote!);
    } else {
      notifyListeners();
    }

    return this;
  }

  void addOverlay(NoteModel overlay) {
    overlays.add(overlay);
    notifyListeners();
  }

  void updateOverlay(int index, NoteModel overlay) {
    if (index < 0 || index >= overlays.length) return;
    if (overlays[index].id != overlay.id) return;
    overlays[index] = overlay;
    notifyListeners();
  }

  void onCreatedNewOverlay(NoteModel overlay) {
    overlays.add(overlay);
    focusOverlay(overlay);
  }

  void focusTemplate() {
    _focusedNote = template;
    notifyListeners();
  }

  void focusOverlay(NoteModel overlay) {
    final existingNote =
        allNotes.where((element) => element.id == overlay.id).firstOrNull;
    if (existingNote == null) {
      debugPrint('Note not found');
      return;
    }
    _focusedNote = existingNote;
    notifyListeners();
  }

  void focusOverlayAt(int index) {
    if (index < 0 || index >= overlays.length) return;
    _focusedNote = overlays[index];
    notifyListeners();
  }

  void focusOverlayByType(NoteType type) {
    if (type == NoteType.template) {
      focusTemplate();
      return;
    }
    _focusedNote =
        overlays.where((element) => element.noteType == type).firstOrNull;
    if (_focusedNote == null) return;
    notifyListeners();
  }

  void focusOverlayByCreator(String creatorId) {
    var toFocus =
        overlays.where((element) => element.createdBy == creatorId).lastOrNull;

    _focusedNote = toFocus;

    debugPrint(
        'Focused note: $_focusedNote, creator: $creatorId, overlays: ${overlays.map((e) => e.hashCode).toList()}');

    notifyListeners();
  }

  void clearFocus() {
    _focusedNote = null;
    notifyListeners();
  }

  void clearOverlays() {
    overlays.clear();
    notifyListeners();
  }

  bool hasNote(String noteId) {
    return template.id == noteId ||
        overlays.any((element) => element.id == noteId);
  }

  bool hasNoteType(NoteType noteType) {
    return template.noteType == noteType ||
        overlays.any((element) => element.noteType == noteType);
  }

  NoteModel? getNoteByNoteType(NoteType noteType) {
    if (template.noteType == noteType) return template;
    return overlays
        .where((element) => element.noteType == noteType)
        .firstOrNull;
  }

  @override
  String toString() {
    return 'NoteModelStack(template: $template, overlays: $overlays, focusedNote: $_focusedNote)';
  }
}
