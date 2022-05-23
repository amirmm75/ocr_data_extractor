import 'package:camera_kit_ext/CameraKitExtController.dart';
import 'package:camera_kit_ext/CameraKitExtView.dart';
import 'package:example/consts.dart';
import 'package:example/line_drawing.dart';
import 'package:example/live_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr_data_extractor/classes.dart';
import 'package:ocr_data_extractor/ocr_data_extractor.dart';
import 'classes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyTestPage(title: 'Back Up'),
    );
  }
}

class MyTestPage extends StatefulWidget {
  const MyTestPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyTestPage> createState() => _MyTestPageState();
}

class _MyTestPageState extends State<MyTestPage> {
  final ImagePicker _picker = ImagePicker();
  bool loading = false;
  int selected = 0;
  int type = 0;
  List<String> results = ['', '', '', '', '', ''];
  List<Line> beforeLines = [];
  List<Line> afterLines = [];

  // Future<void> _getNumbers() async {
  //   setState(() => loading = true);
  //   final pickedFile = await _picker.getImage(source: ImageSource.gallery, imageQuality: 50);
  //   List<String> numbers = await OCRController().getNumberList(pickedFile!.path);
  //   setState(() => loading = false);
  // }

  // Future<void> _getNames() async {
  //   setState(() => loading = true);
  //   final pickedFile = await _picker.getImage(source: ImageSource.gallery, imageQuality: 50);
  //   // print("path is : ${pickedFile!.path}");
  //   dynamic passengers = await OCRController().getNamesList(pickedFile!.path, StaticLists.names, 2);
  //   setState(() => loading = false);
  // }

  // Future<void> _test() async {
  //   setState(() => loading = true);
  //   Map<String, dynamic> d = StaticData.data;
  //   d["orientation"] = "5";
  //   List<Map<String, dynamic>> passengers =
  //       await OCRController().getPassengerListByOCRData(d, StaticLists.names);
  //   List<BackUpOCRPassenger> data = passengers.map((e) => BackUpOCRPassenger.fromJson(e)).toList();
  //   results = [
  //     OCRController().googleText,
  //     OCRController().sortedResult,
  //     OCRController().sortedResultYAxis,
  //     OCRController().sortedResultXAxis,
  //     OCRController().sortedResultSlope,
  //     data.join("\n"),
  //   ];
  //   beforeLines = OCRController().beforeLines;
  //   afterLines = OCRController().afterLines;
  //   setState(() => loading = false);
  // }

  Future<void> _getPassengers() async {
    setState(() => loading = true);
    final pickedFile =
        await _picker.getImage(source: ImageSource.gallery, imageQuality: 50);
    List<Map<String, dynamic>> passengers = await OCRController()
        .getPassengerList(pickedFile!.path, StaticLists.names);
    List<BackUpOCRPassenger> data =
        passengers.map((e) => BackUpOCRPassenger.fromJson(e)).toList();
    results = [
      OCRController().googleText,
      OCRController().sortedResult,
      OCRController().sortedResultYAxis,
      OCRController().sortedResultXAxis,
      OCRController().sortedResultSlope,
      data.join("\n"),
    ];
    beforeLines = OCRController().beforeLines;
    afterLines = OCRController().afterLines;
    setState(() => loading = false);
  }

  Future<void> _takePicture() async {
    setState(() => loading = true);
    String? path = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const _TakePicture()));
    if (path?.isNotEmpty ?? false) {
      List<Map<String, dynamic>> passengers =
          await OCRController().getPassengerList(path!, StaticLists.names);
      List<BackUpOCRPassenger> data =
          passengers.map((e) => BackUpOCRPassenger.fromJson(e)).toList();
      results = [
        OCRController().googleText,
        OCRController().sortedResult,
        OCRController().sortedResultYAxis,
        OCRController().sortedResultXAxis,
        OCRController().sortedResultSlope,
        data.join("\n"),
      ];
    }
    beforeLines = OCRController().beforeLines;
    afterLines = OCRController().afterLines;
    setState(() => loading = false);
  }

  showLines(bool isRaw) {
    Object o = Object(lines: isRaw ? beforeLines : afterLines);
    List<Line> lines = Object.fromJson(o.toJson()).lines ?? [];
    if (lines.isEmpty) {
      Get.snackbar('\nNothing to show!', "",
          duration: const Duration(seconds: 1),
          colorText: Colors.red,
          backgroundColor: Colors.white70);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => LineDrawing(lines: [...lines])));
  }

  @override
  Widget build(BuildContext context) {
    String showingText = '';
    if (selected == 0) {
      showingText = results.first;
    } else if (selected == 1) {
      showingText = results[type + 1];
    } else {
      showingText = results.last;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.raw_on),
            onPressed: () => showLines(true),
          ),
          IconButton(
            icon: const Icon(Icons.raw_off),
            onPressed: () => showLines(false),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: InkWell(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        alignment: Alignment.center,
                        color: Colors.blue.withOpacity(0.5),
                        child: Text("Raw Data",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: 0 == selected
                                    ? TextDecoration.underline
                                    : TextDecoration.none)),
                      ),
                      onTap: () => setState(() => selected = 0),
                    ),
                  ),
                  const VerticalDivider(
                      color: Colors.white, width: 1, thickness: 1),
                  Expanded(
                    child: InkWell(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        alignment: Alignment.center,
                        color: Colors.blue.withOpacity(0.5),
                        child: Text(
                            type == 0
                                ? "Sorted"
                                : type == 1
                                    ? "X Axis"
                                    : type == 2
                                        ? "Y Axis"
                                        : "Slope",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: 1 == selected
                                    ? TextDecoration.underline
                                    : TextDecoration.none)),
                      ),
                      onTap: () => setState(() => selected = 1),
                    ),
                  ),
                  const VerticalDivider(
                      color: Colors.white, width: 1, thickness: 1),
                  Expanded(
                    child: InkWell(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        alignment: Alignment.center,
                        color: Colors.blue.withOpacity(0.5),
                        child: Text("Extracted",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: 2 == selected
                                    ? TextDecoration.underline
                                    : TextDecoration.none)),
                      ),
                      onTap: () => setState(() => selected = 2),
                    ),
                  ),
                ]),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(child: Text(showingText)),
                  ),
                ),
              ],
            ),
      floatingActionButton: Row(
        children: [
          const SizedBox(width: 24),
          FloatingActionButton(
            heroTag: "btn 1",
            onPressed: () {
              Clipboard.setData(ClipboardData(text: showingText));
              Get.snackbar('\nCopied to Clipboard', "",
                  duration: const Duration(seconds: 1),
                  colorText: Colors.black,
                  backgroundColor: Colors.white70);
            },
            child: const Icon(Icons.copy),
          ),
          const SizedBox(width: 9),
          if (selected == 1)
            ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    primary: Colors.amberAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    fixedSize: const Size(100, 50),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => type = (type + 1) % 4),
                icon: const Icon(Icons.change_circle),
                label: const Text('Type')),
          const Spacer(),
          FloatingActionButton(
            heroTag: "btn 2",
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LiveScan()));
            },
            child: const Icon(Icons.video_camera_front),
          ),
          const SizedBox(width: 9),
          FloatingActionButton(
            heroTag: "btn 2.5",
            onPressed: _takePicture,
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(width: 9),
          FloatingActionButton(
            heroTag: "btn 3",
            onPressed: _getPassengers,
            child: const Icon(Icons.attach_file),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class _TakePicture extends StatefulWidget {
  const _TakePicture({Key? key}) : super(key: key);

  @override
  State<_TakePicture> createState() => _TakePictureState();
}

class _TakePictureState extends State<_TakePicture> {
  final CameraKitExtController _cameraKitExtController =
      CameraKitExtController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scanner")),
      backgroundColor: Colors.white,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _cameraKitExtController
            .takePicture()
            .then((value) => Navigator.pop(context, value)),
        child: const Icon(Icons.camera_alt),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.white,
        child: CameraKitExtView(
          cameraKitController: _cameraKitExtController,
          previewFlashMode: CameraFlashMode.auto,
          onPermissionDenied: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
