import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/models/note_mc.model.dart';
import 'package:makernote/services/item/mc.service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MCResponseGraph extends HookWidget {
  const MCResponseGraph({
    super.key,
    required this.questionNumber,
    required this.data,
    this.onDataPointTap,
  });

  final int questionNumber;
  final List<MCPerformance> data;

  // onDataPointTap callback
  final void Function(int)? onDataPointTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SfCircularChart(
              title: ChartTitle(
                  text:
                      'Response Distribution of Question ${questionNumber + 1}',
                  textStyle: Theme.of(context).textTheme.bodyLarge),
              legend: Legend(
                isVisible: true,
                overflowMode: LegendItemOverflowMode.wrap,
                textStyle: Theme.of(context).textTheme.bodyMedium,
                toggleSeriesVisibility: false,
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: _getPieSeries(context),
            );
          },
        ),
      ),
    );
  }

  List<CircularSeries> _getPieSeries(BuildContext context) {
    final optionColors = <Color>[
      const Color(0xff53fdd7),
      const Color(0xffff5182),
      const Color(0xff3d7af7),
      const Color(0xE8FFDF50),
    ];

    // group data by selected option
    final mappedData = <(MCOption, int)>[
      (MCOption.A, 0),
      (MCOption.B, 0),
      (MCOption.C, 0),
      (MCOption.D, 0),
    ];
    for (final response in data) {
      final option = response.selectedOption;
      if (option != null) {
        final index = mappedData.indexWhere((element) => element.$1 == option);
        if (index == -1) {
          mappedData.add((option, 1));
        } else {
          mappedData[index] = (option, mappedData[index].$2 + 1);
        }
      }
    }
    return <CircularSeries>[
      DoughnutSeries<(MCOption, int), String>(
        dataSource: mappedData,
        xValueMapper: ((MCOption, int) mc, _) => mc.$1.name,
        yValueMapper: ((MCOption, int) mc, _) => mc.$2,
        dataLabelSettings: const DataLabelSettings(isVisible: true),
        enableTooltip: true,
        pointColorMapper: ((MCOption, int) mc, _) => optionColors[mc.$1.index],
        onPointTap: (pointInteractionDetails) {
          debugPrint('${pointInteractionDetails.pointIndex}');
          if (pointInteractionDetails.pointIndex != null) {
            onDataPointTap?.call(pointInteractionDetails.pointIndex!);
          }
        },
        // Explode the segments on tap
        explode: true,
        explodeIndex: -1,
      ),
    ];
  }
}
