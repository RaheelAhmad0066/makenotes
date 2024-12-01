import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/services/item/mc.service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MCPerformanceGraph extends HookWidget {
  const MCPerformanceGraph({
    super.key,
    required this.data,
    this.onDataPointTap,
  });

  final List<MCQuestionPerformance> data;

  // onDataPointTap callback
  final void Function(int)? onDataPointTap;

  @override
  Widget build(BuildContext context) {
    final tooltipBehavior = useMemoized(
        () => TooltipBehavior(enable: false, header: '', canShowMarker: true),
        []);
    return AspectRatio(
      aspectRatio: 1.66,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SfCartesianChart(
              zoomPanBehavior: ZoomPanBehavior(
                enablePanning: true,
              ),
              plotAreaBorderWidth: 0,
              title: ChartTitle(
                  text:
                      'Multiple Choice Performance of ${data.length} Questions'),
              legend: const Legend(isVisible: true),
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                title: AxisTitle(text: 'Question'),
                autoScrollingDelta: 6,
                autoScrollingMode: AutoScrollingMode.end,
                labelStyle: Theme.of(context).textTheme.bodyLarge,
              ),
              primaryYAxis: NumericAxis(
                labelFormat: '{value}%',
                rangePadding: ChartRangePadding.none,
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: Theme.of(context).textTheme.bodyLarge,
              ),
              series: _getStackedBarSeries(context, onDataPointTap),
              tooltipBehavior: tooltipBehavior,
            );
          },
        ),
      ),
    );
  }

  List<CartesianSeries<dynamic, dynamic>> _getStackedBarSeries(
    BuildContext context,
    void Function(int)? onDataPointTap,
  ) {
    final data = this.data.reversed.toList();
    if (data.isEmpty) {
      return [];
    }
    const Color correctColor = Color(0xff53fdd7);
    const Color wrongColor = Color(0xffff5182);
    return <CartesianSeries<dynamic, dynamic>>[
      StackedBarSeries<MCQuestionPerformance, String>(
        dataSource: data,
        xValueMapper: (MCQuestionPerformance mc, index) =>
            '${data.length - index}',
        xAxisName: 'Question',
        yValueMapper: (MCQuestionPerformance mc, index) =>
            (mc.correctnessRate * 100).round(),
        yAxisName: 'Percentage',
        name: 'Correct',
        dataLabelSettings: const DataLabelSettings(isVisible: true),
        color: correctColor,
        onPointTap: (pointInteractionDetails) {
          if (pointInteractionDetails.pointIndex != null) {
            onDataPointTap?.call(pointInteractionDetails.pointIndex!);
          }
        },
      ),
      StackedBarSeries<MCQuestionPerformance, String>(
        dataSource: data,
        xValueMapper: (MCQuestionPerformance mc, index) =>
            '${data.length - index}',
        xAxisName: 'Question',
        yValueMapper: (MCQuestionPerformance mc, index) =>
            (100 - mc.correctnessRate * 100).round(),
        yAxisName: 'Percentage',
        name: 'Wrong',
        dataLabelSettings: DataLabelSettings(
          isVisible: true,
          textStyle: Theme.of(context).textTheme.bodyMedium,
        ),
        color: wrongColor,
        onPointTap: (pointInteractionDetails) {
          if (pointInteractionDetails.pointIndex != null) {
            onDataPointTap?.call(pointInteractionDetails.pointIndex!);
          }
        },
      ),
    ];
  }
}
