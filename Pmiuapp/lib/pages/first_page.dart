import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:pmiuapp/widgets/warning_widget.dart';
import 'second_page.dart';
import 'package:pmiuapp/widgets/menubutton.dart';
import '../utils/check.dart';

class PageOne extends StatefulWidget {
  const PageOne({super.key});

  @override
  State<PageOne> createState() => _PageOneState();
}

class _PageOneState extends State<PageOne> {
  Map<String, List> dataMap = {};
  final TextEditingController textEditingController = TextEditingController();

  Future<Map<String, List>> _loadCSV() async {
    final _csvData = await rootBundle.loadString("assets/data/oosc.csv");
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(_csvData);

    setState(() {
      for (var row in csvTable) {
        String key = row[0];
        dataMap[key] = row.sublist(1);
      }
    });
    return dataMap;
  }

  String userInput = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 10,
        actions: [
          menu(),
        ],
        title: const Text(
          'Out Of School Children',
          style: TextStyle(
            color: Color(0xFFEDEEF1),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_image.jpeg'),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 200,
                height: 200,
                child: Image.asset('assets/images/Logo.png'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: textEditingController,
                style: const TextStyle(color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  filled: true,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                  hintText: "Enter District Name",
                  hintStyle: TextStyle(
                    color: Color(0xFFA5A5A8),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(30),
                      right: Radius.circular(30),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(30),
                      right: Radius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  userInput = textEditingController.text;
                });

                Map<String, List> DataSet = await _loadCSV();

                if (Check(userInput, DataSet)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SecondPage(
                        Data: DataSet,
                        input:
                            "${userInput[0].toUpperCase()}${userInput.substring(1).toLowerCase()}",
                      ),
                    ),
                  );
                } else {
                  setState(() {
                    ScaffoldMessenger.of(context).showSnackBar(
                      provideWarningWidget(message: "Incorrect District Name"),
                    );
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E4053), // background color
              ),
              child: const Text(
                "Search",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
