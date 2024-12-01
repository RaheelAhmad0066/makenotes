import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:makernote/models/note_mc.model.dart';
import 'package:makernote/screens/member/overview/mc_overall_performance_view.dart';
import 'package:makernote/services/item/mc.service.dart';
import 'package:makernote/services/user.service.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class MCResponseDataGrid extends HookWidget {
  const MCResponseDataGrid({
    super.key,
    required this.data,
  });

  final List<MCPerformance> data;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Selector<MCOverallPerformanceViewData, MCOption?>(
              selector: (context, data) => data.selectedOption,
              builder: (context, selectedOption, child) {
                return SfDataGrid(
                  source: MCPerformanceDataSource(
                      performances: data
                          .where(
                            (element) =>
                                selectedOption == null ||
                                element.selectedOption == selectedOption,
                          )
                          .toList()),
                  gridLinesVisibility: GridLinesVisibility.both,
                  headerGridLinesVisibility: GridLinesVisibility.both,
                  columnWidthMode: ColumnWidthMode.fill,
                  columns: <GridColumn>[
                    GridColumn(
                      columnName: 'userId',
                      label: Container(
                        padding: const EdgeInsets.all(8),
                        alignment: Alignment.center,
                        child: const Text(
                          'User',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    GridColumn(
                      columnName: 'selectedOption',
                      label: Container(
                        padding: const EdgeInsets.all(8),
                        alignment: Alignment.center,
                        child: const Text(
                          'Chosen Option',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                );
              });
        },
      ),
    );
  }
}

class MCPerformanceDataSource extends DataGridSource {
  MCPerformanceDataSource({
    required List<MCPerformance> performances,
  }) {
    dataGridRows = performances.map((performance) {
      return DataGridRow(cells: [
        DataGridCell<String>(columnName: 'userId', value: performance.userId),
        DataGridCell<String>(
            columnName: 'selectedOption',
            value: performance.selectedOption?.name ?? 'None'),
      ]);
    }).toList();
  }

  List<DataGridRow> dataGridRows = [];

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>(
      (dataGridCell) {
        if (dataGridCell.columnName == 'userId') {
          return FutureBuilder(
            future: UserService().getUser(dataGridCell.value.toString()),
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
                return Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    snapshot.data!.name ?? '--',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }
            },
          );
        }
        return Container(
          padding: const EdgeInsets.all(8),
          child: Text(
            dataGridCell.value.toString(),
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    ).toList());
  }
}
