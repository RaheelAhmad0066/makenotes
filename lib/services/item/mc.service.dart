import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:makernote/models/note_mc.model.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/plugin/drawing_board/services/i_note_mc_service.interface.dart';
import 'package:makernote/services/item/item_service.dart';
import 'package:makernote/services/item/note_service.dart';

class MCService implements INoteMCService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  String? getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Future<void> appendMC(String noteId, int amount, String? ownerId) async {
    final mcRef = db
        .collection('users')
        .doc(ownerId ?? getUserId())
        .collection(ItemService.collectionName)
        .doc(noteId);

    // Fetch the current note document
    final docSnapshot = await mcRef.get();
    final data = docSnapshot.data() as Map<String, dynamic>;
    List<dynamic> multipleChoices = data['multipleChoices'] ?? [];

    // Append new models to the multipleChoices list
    multipleChoices.addAll(
      List.generate(
        amount,
        (index) => NoteMCModel.empty().toMap(),
      ),
    );

    // Update the note document with the new multipleChoices list
    await mcRef.update({'multipleChoices': multipleChoices});
  }

  @override
  Future<void> updateMC(
      String noteId, int index, NoteMCModel mc, String? ownerId) async {
    final mcRef = db
        .collection('users')
        .doc(ownerId ?? getUserId())
        .collection(ItemService.collectionName)
        .doc(noteId);

    final mcSnapshot = await mcRef.get();

    final mcList = mcSnapshot.data()?['multipleChoices'] as List<dynamic>?;
    if (mcList == null) {
      return;
    }

    mcList[index] = mc.toMap();

    await mcRef.update({
      'multipleChoices': mcList,
    });
  }

  @override
  Future<void> deleteMC(
      String noteId, int from, int to, String? ownerId) async {
    debugPrint('Deleting MC from $from to $to');
    final mcRef = db
        .collection('users')
        .doc(ownerId ?? getUserId())
        .collection(ItemService.collectionName)
        .doc(noteId);

    final mcSnapshot = await mcRef.get();

    final mcList = mcSnapshot.data()?['multipleChoices'] as List<dynamic>?;

    if (mcList == null) {
      return;
    }

    mcList.removeRange(from, to);

    try {
      await mcRef.update({
        'multipleChoices': mcList,
      });
    } catch (e) {
      debugPrint('Error deleting MC: $e');
      rethrow;
    }
  }

  @override
  Future<List<NoteMCModel>> getMC(String noteId, String? ownerId) async {
    final mcRef = db
        .collection('users')
        .doc(ownerId ?? getUserId())
        .collection(ItemService.collectionName)
        .doc(noteId);

    final mcSnapshot = await mcRef.get();

    final mc = mcSnapshot.data()?['multipleChoices'] as List<dynamic>?;

    if (mc == null) {
      return [];
    }

    return mc.map((e) => NoteMCModel.fromMap(e)).toList();
  }

  @override
  Stream<List<NoteMCModel>> getMCStream(String noteId, String? ownerId) {
    final mcRef = db
        .collection('users')
        .doc(ownerId ?? getUserId())
        .collection(ItemService.collectionName)
        .doc(noteId);

    return mcRef.snapshots().map((snapshot) {
      final mc = snapshot.data()?['multipleChoices'] as List<dynamic>?;

      if (mc == null) {
        return [];
      }

      return mc.map((e) => NoteMCModel.fromMap(e)).toList();
    });
  }

  (
    List<MCQuestionPerformance> correctRates,
    String noteId,
    String ownerId,
    Timestamp expireAt,
  )? _cachedMCQuestionStats;

  bool hasCache(String templateNoteId, String? ownerId) {
    return _cachedMCQuestionStats != null &&
        _cachedMCQuestionStats!.$2 == templateNoteId &&
        _cachedMCQuestionStats!.$3 == ownerId &&
        DateTime.now().isBefore(_cachedMCQuestionStats!.$4.toDate());
  }

  void clearCache() {
    _cachedMCQuestionStats = null;
  }

  void cacheResults(
    List<MCQuestionPerformance> correctRates,
    String noteId,
    String ownerId,
    Timestamp expireAt,
  ) {
    _cachedMCQuestionStats = (
      correctRates,
      noteId,
      ownerId,
      expireAt,
    );
  }

  Future<List<MCQuestionPerformance>> getOverallCorrectRate(
    String templateNoteId,
    String? ownerId,
  ) async {
    debugPrint('Getting overall correct rate for $templateNoteId');
    final noteService = NoteService();

    if (hasCache(templateNoteId, ownerId)) {
      return _cachedMCQuestionStats?.$1 ?? [];
    }

    clearCache();

    // verify that the template note exists
    final templateNote = await noteService.getNote(
      templateNoteId,
      ownerId,
    );
    if (templateNote.noteType != NoteType.template) {
      throw Exception('Template note does not exist');
    }

    final allTemplateMC = await getMC(templateNoteId, ownerId);

    final exerciseNotes = await noteService.getOverlayNotes(
      noteId: templateNoteId,
      type: NoteType.exercise,
    );

    final Map<String, List<List<NoteMCModel>>> allExerciseMC = {};
    await Future.wait(
      exerciseNotes.map((exerciseNote) async {
        final mc = await getMC(exerciseNote.id!, ownerId);
        if (allExerciseMC.containsKey(exerciseNote.createdBy)) {
          allExerciseMC[exerciseNote.createdBy]!.add(mc);
        } else {
          allExerciseMC[exerciseNote.createdBy] = [mc];
        }
      }),
    );

    final List<MCQuestionPerformance> correctRates = [];

    for (int i = 0; i < allTemplateMC.length; i++) {
      final templateMC = allTemplateMC[i];
      final performances = <MCPerformance>[];

      int correct = 0;
      int total = 0;

      for (var entry in allExerciseMC.entries) {
        for (var mcList in entry.value) {
          bool isCorrect = templateMC.correctAnswer != null &&
              mcList[i].correctAnswer == templateMC.correctAnswer;
          // add performance
          performances.add(MCPerformance(
            userId: entry.key,
            isCorrect: isCorrect,
            selectedOption: mcList[i].correctAnswer,
          ));
          if (isCorrect) {
            correct++;
          }
          total++;
        }
      }

      correctRates.add(MCQuestionPerformance(
        questionNumber: i,
        correctCount: correct,
        totalResponses: total,
        correctOption: templateMC.correctAnswer,
        userResponses: performances,
      ));
    }

    cacheResults(
      correctRates,
      templateNoteId,
      ownerId ?? getUserId()!,
      Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 1))),
    );

    return correctRates;
  }

  Future<MCQuestionPerformance?> getMCCorrectRate({
    required String templateNoteId,
    String? ownerId,
    int questionNumber = 0,
  }) async {
    // check cache
    if (hasCache(templateNoteId, ownerId)) {
      // return cached results
      final cachedResults = _cachedMCQuestionStats!;

      final correctRates = cachedResults.$1;

      return correctRates[questionNumber];
    } else {
      var results = await getOverallCorrectRate(templateNoteId, ownerId);

      if (results.isEmpty) {
        return null;
      }

      return results[questionNumber];
    }
  }

  Future<MarkResult> getMarkResult(
    String templateNoteId,
    String? ownerId,
  ) async {
    try {
      if (hasCache(templateNoteId, ownerId)) {
        final cachedResults = _cachedMCQuestionStats!;

        final correctRates = cachedResults.$1;

        final totalScore = correctRates.length;
        Map<String, int> userScoreMap = {};
        userScoreMap = correctRates.fold<Map<String, int>>(
          userScoreMap,
          (previousValue, element) {
            final userResponses = element.userResponses;
            for (final userResponse in userResponses) {
              previousValue[userResponse.userId] =
                  (previousValue[userResponse.userId] ?? 0) +
                      (userResponse.isCorrect ? 1 : 0);
            }
            return previousValue;
          },
        );

        return MarkResult(
          highestScore: userScoreMap.values
              .reduce((value, element) => value > element ? value : element),
          averageScore:
              userScoreMap.values.reduce((value, element) => value + element) ~/
                  userScoreMap.length,
          lowestScore: userScoreMap.values
              .reduce((value, element) => value < element ? value : element),
          totalScore: totalScore,
        );
      } else {
        final results = await getOverallCorrectRate(templateNoteId, ownerId);

        final totalScore = results.length;
        Map<String, int> userScoreMap = {};
        userScoreMap = results.fold<Map<String, int>>(
          userScoreMap,
          (previousValue, element) {
            final userResponses = element.userResponses;
            for (final userResponse in userResponses) {
              previousValue[userResponse.userId] =
                  (previousValue[userResponse.userId] ?? 0) +
                      (userResponse.isCorrect ? 1 : 0);
            }
            return previousValue;
          },
        );

        return MarkResult(
          highestScore: userScoreMap.values
              .reduce((value, element) => value > element ? value : element),
          averageScore:
              userScoreMap.values.reduce((value, element) => value + element) ~/
                  userScoreMap.length,
          lowestScore: userScoreMap.values
              .reduce((value, element) => value < element ? value : element),
          totalScore: totalScore,
        );
      }
    } catch (e) {
      // debugPrint('Error getting mark result: $e');
      return MarkResult(
        highestScore: 0,
        averageScore: 0,
        lowestScore: 0,
        totalScore: 0,
      );
    }
  }
}

class MarkResult {
  final int highestScore;
  final int averageScore;
  final int lowestScore;
  final int totalScore;

  MarkResult({
    required this.highestScore,
    required this.averageScore,
    required this.lowestScore,
    required this.totalScore,
  });
}

class MCQuestionPerformance {
  MCQuestionPerformance({
    required this.questionNumber,
    required this.correctCount,
    required this.totalResponses,
    required this.correctOption,
    required this.userResponses,
  });

  final int questionNumber;
  final int correctCount;
  final int totalResponses;
  final MCOption? correctOption;
  final List<MCPerformance> userResponses;

  double get correctnessRate => totalResponses == 0
      ? 0
      : correctCount.toDouble() / totalResponses.toDouble();

  @override
  String toString() {
    return 'MCQuestionPerformance(\n'
        '\tquestionNumber: $questionNumber,\n'
        '\tcorrectCount: $correctCount,\n'
        '\ttotalResponses: $totalResponses,\n'
        '\tcorrectOption: $correctOption,\n'
        '\tuserResponses: $userResponses,\n'
        '\n)';
  }
}

class MCPerformance {
  MCPerformance({
    required this.userId,
    required this.isCorrect,
    required this.selectedOption,
  });

  final String userId;
  final bool isCorrect;
  final MCOption? selectedOption;

  @override
  String toString() {
    return 'MCPerformance(\n'
        '\tuserId: $userId,\n'
        '\tisCorrect: $isCorrect,\n'
        '\tselectedOption: $selectedOption,\n'
        ')\n';
  }
}
