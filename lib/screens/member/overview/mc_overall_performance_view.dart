import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/main.dart';
import 'package:makernote/models/note_mc.model.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/services/item/mc.service.dart';
import 'package:makernote/widgets/flex.extension.dart';
import 'package:provider/provider.dart';

import 'graphs/mc_mark_distribution.graph.dart';
import 'graphs/mc_performance.graph.dart';
import 'graphs/mc_response.graph.dart';
import 'graphs/mc_response_data_grid.graph.dart';

class MCOverallPerformanceView extends HookWidget {
  const MCOverallPerformanceView({super.key});

  List<MarkDistributionData> convertToMarkDistributionData(
      List<MCQuestionPerformance> data) {
    Map<String, int> userScoreMap = {};
    userScoreMap = data.fold<Map<String, int>>(
      userScoreMap,
      (previousValue, element) {
        final userResponses = element.userResponses;
        for (final userResponse in userResponses) {
          if (userResponse.isCorrect) {
            previousValue[userResponse.userId] =
                (previousValue[userResponse.userId] ?? 0) + 1;
          }
        }
        return previousValue;
      },
    );

    final maxScore = data.length;
    final markDistributionData = <MarkDistributionData>[];

    for (var i = 0; i < maxScore; i++) {
      markDistributionData.add(
        MarkDistributionData(
          mark: i + 1,
          count:
              userScoreMap.values.where((element) => element == i + 1).length,
        ),
      );
    }

    return markDistributionData;
  }

  @override
  Widget build(BuildContext context) {
    final mcService = Provider.of<MCService>(context);
    final noteModel = Provider.of<NoteModel>(context);
    return ChangeNotifierProvider(
      create: (_) => MCOverallPerformanceViewData(),
      builder: (context, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MC performance graph
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FutureBuilder(
                        future: mcService.getOverallCorrectRate(
                            noteModel.id!, noteModel.ownerId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(snapshot.error.toString()),
                            );
                          } else {
                            return MCPerformanceGraph(
                              data: snapshot.data ?? [],
                              onDataPointTap: (index) {
                                final data =
                                    Provider.of<MCOverallPerformanceViewData>(
                                        context,
                                        listen: false);

                                data.selectedQuestionIndex =
                                    snapshot.data!.length - index - 1;
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      // hightest mark card
                      Expanded(
                        flex: 1,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Highest Mark',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .extension<CustomColors>()
                                            ?.success,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder(
                                  future: mcService.getMarkResult(
                                      noteModel.id!, noteModel.ownerId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Center(
                                        child: Text(snapshot.error.toString()),
                                      );
                                    } else if (snapshot.data == null) {
                                      return const Center(
                                        child: Text('No data'),
                                      );
                                    } else {
                                      return Text(
                                        '${snapshot.data!.highestScore} / ${snapshot.data!.totalScore}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // average mark card
                      Expanded(
                        flex: 1,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Average Mark',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .extension<CustomColors>()
                                            ?.warning,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder(
                                  future: mcService.getMarkResult(
                                      noteModel.id!, noteModel.ownerId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Center(
                                        child: Text(snapshot.error.toString()),
                                      );
                                    } else if (snapshot.data == null) {
                                      return const Center(
                                        child: Text('No data'),
                                      );
                                    } else {
                                      return Text(
                                        '${snapshot.data!.averageScore} / ${snapshot.data!.totalScore}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // lowest mark card
                      Expanded(
                        flex: 1,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lowest Mark',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .extension<CustomColors>()
                                            ?.danger,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder(
                                  future: mcService.getMarkResult(
                                      noteModel.id!, noteModel.ownerId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Center(
                                        child: Text(snapshot.error.toString()),
                                      );
                                    } else if (snapshot.data == null) {
                                      return const Center(
                                        child: Text('No data'),
                                      );
                                    } else {
                                      return Text(
                                        '${snapshot.data!.lowestScore} / ${snapshot.data!.totalScore}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // MC mark distribution graph
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FutureBuilder(
                        future: mcService.getOverallCorrectRate(
                            noteModel.id!, noteModel.ownerId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(snapshot.error.toString()),
                            );
                          } else {
                            return MCMarkDistributionGraph(
                              data:
                                  convertToMarkDistributionData(snapshot.data!),
                              onDataPointTap: (index) {
                                final data =
                                    Provider.of<MCOverallPerformanceViewData>(
                                        context,
                                        listen: false);

                                data.selectedQuestionIndex =
                                    snapshot.data!.length - index - 1;
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              flex: 1,
              child: Card(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Selector<MCOverallPerformanceViewData, int?>(
                        selector: (context, data) => data.selectedQuestionIndex,
                        shouldRebuild: (prev, next) => prev != next,
                        builder: (context, index, child) {
                          if (index == null) {
                            return const Center(
                              child: Text('Select a question to view details'),
                            );
                          } else {
                            return Stack(
                              children: [
                                FutureBuilder(
                                  future: mcService.getMCCorrectRate(
                                    templateNoteId: noteModel.id!,
                                    ownerId: noteModel.ownerId,
                                    questionNumber: index,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Center(
                                        child: Text(snapshot.error.toString()),
                                      );
                                    } else if (snapshot.data == null) {
                                      return const Center(
                                        child: Text('No data'),
                                      );
                                    } else {
                                      final data = snapshot.data!;
                                      return IntrinsicHeight(
                                        child: FlexWithExtension.withSpacing(
                                          key: ValueKey(
                                              snapshot.data!.questionNumber),
                                          direction: Axis.vertical,
                                          spacing: 16,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // options pie-chart
                                            Flexible(
                                              flex: 1,
                                              fit: FlexFit.loose,
                                              child: MCResponseGraph(
                                                questionNumber:
                                                    data.questionNumber,
                                                data: data.userResponses,
                                                onDataPointTap: (index) {
                                                  final data = Provider.of<
                                                          MCOverallPerformanceViewData>(
                                                      context,
                                                      listen: false);

                                                  if (data.selectedOption ==
                                                      MCOption.values[index]) {
                                                    data.selectedOption = null;
                                                  } else {
                                                    data.selectedOption =
                                                        MCOption.values[index];
                                                  }
                                                },
                                              ),
                                            ),

                                            // correct option
                                            Flexible(
                                              flex: 0,
                                              fit: FlexFit.loose,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Correct Option',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge,
                                                  ),
                                                  Text(
                                                    data.correctOption?.name ??
                                                        'None',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headlineMedium
                                                        ?.copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .extension<
                                                                    CustomColors>()
                                                                ?.success),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // user response list
                                            Flexible(
                                              flex: 0,
                                              fit: FlexFit.loose,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'User Responses',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge,
                                                  ),
                                                  MCResponseDataGrid(
                                                    data: data.userResponses,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                                // closee button
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    mouseCursor: SystemMouseCursors.click,
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      final data = Provider.of<
                                              MCOverallPerformanceViewData>(
                                          context,
                                          listen: false);
                                      data.selectedQuestionIndex = null;
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class MCOverallPerformanceViewData extends ChangeNotifier {
  int? get selectedQuestionIndex => _selectedQuestionIndex;
  int? _selectedQuestionIndex;
  set selectedQuestionIndex(int? value) {
    _selectedQuestionIndex = value;
    _selectedOption = null;
    notifyListeners();
  }

  MCOption? get selectedOption => _selectedOption;
  MCOption? _selectedOption;
  set selectedOption(MCOption? value) {
    _selectedOption = value;
    notifyListeners();
  }
}
