import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:pmiuapp/widgets/menubutton.dart';
import 'package:pmiuapp/widgets/displayfigures.dart';
import 'package:pmiuapp/utils/SmallMap.dart';
import 'package:pmiuapp/utils/all_map.dart';

class SecondPage extends StatelessWidget {
  const SecondPage({super.key, required this.Data, this.input});

  final String? input;
  final Map<String, List> Data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          menu(),
        ],
        title: const Text(
          "Statistics",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
            fontSize: 30,
          ),
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.all(12.0),
                child: input != "All"
                    ? Text(
                        'District ${input!.splitMapJoin(
                          ' ',
                          onNonMatch: (str) =>
                              str[0].toUpperCase() +
                              str.substring(1).toLowerCase(),
                        )}',
                        style: const TextStyle(
                          fontSize: 30,
                        ),
                      )
                    : const Text(
                        "All Districts",
                        style: TextStyle(
                          fontSize: 30,
                        ),
                      )),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: input != "All"
                  ? SmallMap(loc: LatLng(Data[input]![3], Data[input]![4]))
                  : AllMap(),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Graph',
                style: TextStyle(
                  fontSize: 25,
                ),
              ),
            ),
            SfCartesianChart(
                          // Initialize category axis
                          primaryYAxis: NumericAxis(),
                          primaryXAxis: CategoryAxis(),
                          series: [
            ColumnSeries(
              dataSource: [
                {
                  'category': 'Out of School',
                  'Amount': ChartData(
                      "Out of School",
                      int.parse(Data[input]![1]
                          .replaceAll(',', '')
                          .replaceAll(' ', '')))
                },
                {
                  'category': 'In School',
                  'Amount': ChartData(
                      "In School",
                      int.parse(Data[input]![2]
                              .replaceAll(',', '')
                              .replaceAll(' ', '')) -
                          int.parse(Data[input]![1]
                              .replaceAll(',', '')
                              .replaceAll(' ', '')))
                },
                {
                  'category': 'Total Children',
                  'Amount': ChartData(
                      "All Children",
                      int.parse(Data[input]![2]
                          .replaceAll(',', '')
                          .replaceAll(' ', '')))
                }
              ],
              xValueMapper: (data, _) => data['category'],
              yValueMapper: (data, _) => data['Amount'].y,
            ),
                          ],
                        ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                child: const Text(
                  "Figures",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CardWidget(toDisplay: [
                  "Total Children Between 5-16:",
                  "${Data[input]![2].replaceAll(' ', '')}"
                ]),
                CardWidget(toDisplay: [
                  "Out of School Children:",
                  "${Data[input]![1].replaceAll(' ', '')}"
                ]),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CardWidget(toDisplay: [
                  "In School Children:",
                  calculateDifference(Data, input)
                      .toStringAsFixed(0)
                      .replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      )
                ]),
                CardWidget(toDisplay: [
                  "% of Children out of School:",
                  "${Data[input]![0]}"
                ]),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "*Note that all these are estimated values.",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  ChartData(this.x, this.y);

  final String x;
  final int? y;
}

int calculateDifference(Map<String, List<dynamic>> data, String? input) {
  final firstValue = int.parse(data[input]![1].replaceAll(RegExp(r'[ ,]'), ''));
  final secondValue =
      int.parse(data[input]![2].replaceAll(RegExp(r'[ ,]'), ''));
  return secondValue - firstValue;
}