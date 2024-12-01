import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/models/inspecting_user.wrapper.dart';
import 'package:makernote/models/note.wrapper.dart';
import 'package:makernote/models/note_model.dart';
import 'package:makernote/plugin/drawing_board/util/widgets/mc_result.dart';
import 'package:makernote/screens/home_screen.dart';
import 'package:makernote/screens/member/overview/panels/response.panel.dart';
import 'package:makernote/services/item/mc.service.dart';
import 'package:makernote/services/item/note_service.dart';
import 'package:makernote/utils/multi_panel.controller.dart';
import 'package:makernote/utils/routes.dart';
import 'package:makernote/widgets/flex.extension.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'mc_overall_performance_view.dart';
import 'panels/general_info.panel.dart';

class OverviewScreen extends HookWidget {
  const OverviewScreen({
    super.key,
    required this.noteId,
    this.ownerId,
  });

  final String noteId;
  final String? ownerId;

  @override
  Widget build(BuildContext context) {
    final noteService = Provider.of<NoteService>(context);
    final noteFuture =
        useState<Future<NoteModel>>(noteService.getNote(noteId, ownerId));
    final mcService = useRef(MCService());
    final isLoading = useState(false);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MultiPanelController.fromNames(
            ['info', 'response', 'mcResult'],
            defaultOpen: 'response',
          ),
        ),
        Provider.value(value: mcService.value),
      ],
      child: Container(
        color: Theme.of(context).colorScheme.background,
        child: FutureBuilder(
          future: noteFuture.value,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error.toString()),
              );
            } else {
              NoteModel noteModel = snapshot.data as NoteModel;
              return Container(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // back
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            if (beamerKey
                                    .currentState?.routerDelegate.canBeamBack ==
                                true) {
                              beamerKey.currentState?.routerDelegate.beamBack();
                            } else {
                              beamerKey.currentState?.routerDelegate.beamToNamed(
                                  '${Routes.documentScreen}/${noteModel.parentId ?? ''}');
                            }
                          },
                        ),

                        // title
                        Expanded(
                          child: Text(
                            'Overview',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        ),

                        // actions
                        Wrap(
                          spacing: 8,
                          children: [
                            // export excel
                            IconButton(
                              icon: const Icon(
                                Symbols.file_save,
                                color: Colors.green,
                              ),
                              onPressed: isLoading.value == true
                                  ? null
                                  : () async {
                                      isLoading.value = true;
                                      await noteService
                                          .exportExcel(noteModel.id!);
                                      isLoading.value = false;
                                    },
                            ),

                            // edit
                            IconButton(
                              icon: const Icon(Icons.edit_document),
                              onPressed: () {
                                if (ownerId == null) {
                                  beamerKey.currentState?.routerDelegate
                                      .beamToNamed('/note/${noteModel.id}');
                                } else {
                                  beamerKey.currentState?.routerDelegate
                                      .beamToNamed(
                                          '/note/${noteModel.id}/$ownerId');
                                }
                              },
                            ),

                            // info
                            IconButton(
                              icon: const Icon(Symbols.info),
                              onPressed: () {
                                final multiPanelController =
                                    Provider.of<MultiPanelController>(context,
                                        listen: false);
                                if (multiPanelController.isPanelOpen('info')) {
                                  multiPanelController.closePanel('info');
                                } else {
                                  multiPanelController.openPanel('info');
                                }
                              },
                            ),

                            // response
                            IconButton(
                              icon: const Icon(Symbols.group),
                              onPressed: () {
                                final multiPanelController =
                                    Provider.of<MultiPanelController>(context,
                                        listen: false);
                                if (multiPanelController
                                    .isPanelOpen('response')) {
                                  multiPanelController.closePanel('response');
                                } else {
                                  multiPanelController.openPanel('response');
                                }
                              },
                            ),

                            // refresh button
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () {
                                mcService.value.clearCache();
                                noteFuture.value =
                                    noteService.getNote(noteId, ownerId);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(),

                    Expanded(
                      child: MultiProvider(
                        providers: [
                          ChangeNotifierProvider(
                            create: (_) => InspectingUserWrapper(),
                          ),
                          ChangeNotifierProvider(create: (_) => NoteWrapper()),
                        ],
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // content
                              Expanded(
                                child: SizedBox(
                                  height: double.infinity,
                                  child: SingleChildScrollView(
                                    child: FlexWithExtension.withSpacing(
                                      spacing: 16,
                                      direction: Axis.vertical,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ChangeNotifierProvider.value(
                                          value: noteModel,
                                          builder: (context, child) {
                                            return const MCOverallPerformanceView();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // general info
                              SizedBox(
                                height: double.infinity,
                                child: GeneralInfoPanel(noteModel: noteModel),
                              ),

                              // response
                              SizedBox(
                                height: double.infinity,
                                child: ResponsePanel(
                                  noteId: noteModel.id!,
                                ),
                              ),

                              // specific user mc result
                              SizedBox(
                                height: double.infinity,
                                child:
                                    UserMCResultPanel(templateNode: noteModel),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class UserMCResultPanel extends HookWidget {
  const UserMCResultPanel({
    super.key,
    required this.templateNode,
  });

  final NoteModel templateNode;

  static const String panelName = 'mcResult';

  @override
  Widget build(BuildContext context) {
    return Consumer<MultiPanelController>(
      builder: (context, multiPanelController, children) {
        return Card(
          margin: multiPanelController.isPanelOpen(panelName)
              ? null
              : const EdgeInsets.all(0),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: SizedBox(
              width: multiPanelController.isPanelOpen(panelName) ? 320 : 0,
              child: Visibility(
                visible: multiPanelController.isPanelOpen(panelName),
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: AnimatedOpacity(
                  opacity: multiPanelController.isPanelOpen(panelName) ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Consumer2<InspectingUserWrapper, NoteWrapper>(
                      builder: (context, userWrapper, noteWrapper, child) {
                        return Consumer<MultiPanelController>(
                          builder: (context, controller, child) {
                            if (userWrapper.user == null ||
                                noteWrapper.note == null) {
                              return const SizedBox();
                            }
                            return MCResult(
                              controllerKey: panelName,
                              controller: controller,
                              templateReference: templateNode.toReference(),
                              targetReference: noteWrapper.note!.toReference(),
                              onPanelClose: () {
                                controller.openPanel('response');
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
