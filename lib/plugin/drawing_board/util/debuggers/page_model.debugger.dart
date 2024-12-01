import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/plugin/drawing_board/models/page_model.dart';
import 'package:provider/provider.dart';

import 'graphic_element.debugger.dart';

class PageModelDebugger extends HookWidget {
  const PageModelDebugger({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PageModel?>(
      builder: (context, page, child) {
        if (page == null) {
          return const SizedBox();
        } else {
          return Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primaryContainer.withAlpha(169),
              borderRadius: BorderRadius.circular(5),
            ),
            child: ExpansionTile(
              title: const Text('Page Model'),
              tilePadding: const EdgeInsets.all(8),
              childrenPadding: const EdgeInsets.all(8),
              expandedAlignment: Alignment.centerLeft,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Page Model: ${page.hashCode}'),
                Text('Page ID: ${page.id}'),
                Text('Page Order: ${page.order}'),
                Text('Page Size: ${page.size}'),
                Text('Page Background: ${page.backgroundImageUrl}'),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withAlpha(85),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.all(8),
                    childrenPadding: const EdgeInsets.all(8),
                    expandedAlignment: Alignment.centerLeft,
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    title: Text(
                        'Graphic Elements (${page.graphicElements.length})'),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withAlpha(169),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: ListView.builder(
                          cacheExtent: 0.0,
                          shrinkWrap: true,
                          itemCount: page.graphicElements.length,
                          itemBuilder: (context, index) {
                            return MultiProvider(
                              providers: [
                                ChangeNotifierProvider.value(
                                  value: page.graphicElements[index],
                                ),
                              ],
                              builder: (context, child) {
                                return const GraphicElementDebugger();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: page.sketch),
                  ],
                  builder: (context, child) {
                    return const GraphicElementDebugger();
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
