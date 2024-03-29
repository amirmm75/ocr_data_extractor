import 'package:artemis_camera_kit/artemis_camera_kit_controller.dart';
import 'package:artemis_camera_kit/artemis_camera_kit_platform_interface.dart';
import 'package:artemis_camera_kit/artemis_camera_kit_view.dart';
import 'package:example/consts.dart';
import 'package:example/line_drawing.dart';
import 'package:example/live_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
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
  ArtemisCameraKitController ckc = ArtemisCameraKitController();
  final ImagePicker _picker = ImagePicker();
  bool loading = false;
  int selected = 0;
  int type = 0;
  List<String> results = ['', '', '', '', '', ''];
  List<OcrLine> beforeLines = [];
  List<OcrLine> afterLines = [];

  Future<void> _getPassengers() async {
    setState(() => loading = true);
    final pickedFile = await _picker.getImage(source: ImageSource.gallery, imageQuality: 50);
    OcrData? ocrData = await ckc.processImageFromPath(pickedFile?.path ?? '');
    List<Map<String, dynamic>> passengers =
        await OCRController().getPassengerListByOCRData(ocrData!, StaticLists.names);
    List<BackUpOCRPassenger> data = passengers.map((e) => BackUpOCRPassenger.fromJson(e)).toList();
    results = [
      OCRController().googleText,
      OCRController().sortedResult,
      '', '', '',
      // OCRController().sortedResultYAxis,
      // OCRController().sortedResultXAxis,
      // OCRController().sortedResultSlope,
      data.join("\n"),
    ];
    beforeLines = OCRController().beforeLines;
    afterLines = OCRController().afterLines;
    setState(() => loading = false);
  }

  Future<void> _takePicture() async {
    try {
      setState(() => loading = true);
      String? path = await Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => _TakePicture(controller: ckc)));
      if (path?.isNotEmpty ?? false) {
        final result = await ckc.processImageFromPath(path ?? '');
        List<Map<String, dynamic>> passengers =
            await OCRController().getPassengerListByOCRData(result!, StaticLists.names2);
        print(passengers.join("\n"));
        setState(() => loading = false);
        return;
        List<BackUpOCRPassenger> data = passengers.map((e) => BackUpOCRPassenger.fromJson(e)).toList();
        results = [
          result.text,
          OCRController().sortedResult,
          '', '', '',
          // OCRController().sortedResultYAxis,
          // OCRController().sortedResultXAxis,
          // OCRController().sortedResultSlope,
          data.join("\n\n"),
        ];
      }
      beforeLines = OCRController().beforeLines;
      afterLines = OCRController().afterLines;
      setState(() => loading = false);
    } catch (e, s) {
      results[0] = e.toString() + '\n' + s.toString();
      results[1] = e.toString() + '\n' + s.toString();
      print(e.toString() + '\n' + s.toString());
      setState(() => loading = false);
    }
  }

  showLines(bool isRaw) {
    List<OcrLine> lines = isRaw ? beforeLines : afterLines;
    lines = OcrData.fromJson(OcrData(lines: lines, text: '').toJson()).lines;
    if (lines.isEmpty) {
      Get.snackbar('\nNothing to show!', "",
          duration: const Duration(seconds: 1), colorText: Colors.red, backgroundColor: Colors.white70);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => LineDrawing(lines: [...lines])));
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
                                decoration: 0 == selected ? TextDecoration.underline : TextDecoration.none)),
                      ),
                      onTap: () => setState(() => selected = 0),
                    ),
                  ),
                  const VerticalDivider(color: Colors.white, width: 1, thickness: 1),
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
                                decoration: 1 == selected ? TextDecoration.underline : TextDecoration.none)),
                      ),
                      onTap: () => setState(() => selected = 1),
                    ),
                  ),
                  const VerticalDivider(color: Colors.white, width: 1, thickness: 1),
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
                                decoration: 2 == selected ? TextDecoration.underline : TextDecoration.none)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    fixedSize: const Size(100, 50),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => type = (type + 1) % 4),
                icon: const Icon(Icons.change_circle),
                label: const Text('Type')),
          const Spacer(),
          FloatingActionButton(
            heroTag: "btn 2",
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LiveScan()));
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
  final ArtemisCameraKitController controller;

  const _TakePicture({Key? key, required this.controller}) : super(key: key);

  @override
  State<_TakePicture> createState() => _TakePictureState();
}

class _TakePictureState extends State<_TakePicture> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scanner")),
      backgroundColor: Colors.white,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => widget.controller.takePicture().then((value) => Navigator.pop(context, value)),
        child: const Icon(Icons.camera_alt),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.white,
        child: ArtemisCameraKitView(controller: widget.controller, hasBarcodeReader: false),
      ),
    );
  }
}
