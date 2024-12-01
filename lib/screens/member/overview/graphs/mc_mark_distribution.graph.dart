import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MCMarkDistributionGraph extends HookWidget {
  const MCMarkDistributionGraph({
    super.key,
    required this.data,
    this.onDataPointTap,
  });

  final List<MarkDistributionData> data;

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
                  // enablePanning: true,
                  ),
              plotAreaBorderWidth: 0,
              title: ChartTitle(text: 'Multiple Choice Mark Distribution'),
              legend: const Legend(
                isVisible: false,
              ),
              primaryXAxis: NumericAxis(
                title: AxisTitle(text: 'Mark'),
                name: 'Marks',
                labelFormat: '{value}',
                rangePadding: ChartRangePadding.none,
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: Theme.of(context).textTheme.bodyLarge,
                interval: 1,
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(text: 'Number of participants'),
                name: 'Number of participants',
                labelFormat: '{value}',
                rangePadding: ChartRangePadding.none,
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: Theme.of(context).textTheme.bodyLarge,
                interval: 1,
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
    const Color correctColor = Color(0xff53fdd7);
    return <CartesianSeries<dynamic, dynamic>>[
      ColumnSeries<MarkDistributionData, int>(
        dataSource: data,
        xValueMapper: (MarkDistributionData distribution, index) =>
            distribution.mark,
        yValueMapper: (MarkDistributionData distribution, index) =>
            distribution.count,
        name: 'Marks',
        xAxisName: 'Marks',
        yAxisName: 'Number of participants',
        dataLabelSettings: const DataLabelSettings(isVisible: true),
        color: correctColor,
        onPointTap: (pointInteractionDetails) {
          if (pointInteractionDetails.pointIndex != null) {
            onDataPointTap?.call(pointInteractionDetails.pointIndex!);
          }
        },
      ),
    ];
  }
}

class MarkDistributionData {
  final int mark;
  final int count;

  MarkDistributionData({required this.mark, required this.count});
}
