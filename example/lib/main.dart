import 'package:camerakit/CameraKitController.dart';
import 'package:camerakit/CameraKitView.dart';
import 'package:example/consts.dart';
import 'package:flutter/material.dart';
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
      home: const MyTestPage(title: 'Back Up DCS'),
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
  List<String> results = ['', '', ''];

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

  Future<void> _getPassengers() async {
    setState(() => loading = true);
    final pickedFile = await _picker.getImage(source: ImageSource.gallery, imageQuality: 50);
    // print("path is : ${pickedFile!.path}");
    List<Map<String, dynamic>> passengers =
        await OCRController().getPassengerList(pickedFile!.path, StaticLists.names);
    results = [OCRController().googleText, OCRController().sortedResult, passengers.join("\n")];
    setState(() => loading = false);
  }

  Future<void> _takePicture() async {
    setState(() => loading = true);
    String? path =
        await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const _TakePicture()));
    if (path?.isNotEmpty ?? false) {
      List<Map<String, dynamic>> passengers =
          await OCRController().getPassengerList(path!, StaticLists.names);
      List<BackUpOCRPassenger> data = passengers.map((e) => BackUpOCRPassenger.fromJson(e)).toList();
      results = [OCRController().googleText, OCRController().sortedResult, data.join("\n")];
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
                        child: Text("Phase 0",
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
                        child: Text("Phase 1",
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
                        child: Text("Phase 2",
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
                    child: SingleChildScrollView(child: Text(results[selected])),
                  ),
                ),
              ],
            ),
      floatingActionButton: Row(
        children: [
          const Spacer(),
          FloatingActionButton(
            heroTag: "btn 1",
            onPressed: _takePicture,
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            heroTag: "btn 2",
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
  final CameraKitController _cameraKitController = CameraKitController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scanner")),
      backgroundColor: Colors.white,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _cameraKitController.takePicture().then((value) => Navigator.pop(context, value)),
        child: const Icon(Icons.camera_alt),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.white,
        child: CameraKitView(
          cameraKitController: _cameraKitController,
          previewFlashMode: CameraFlashMode.auto,
          onPermissionDenied: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
