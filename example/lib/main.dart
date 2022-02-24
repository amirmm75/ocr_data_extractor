import 'package:camerakit/CameraKitController.dart';
import 'package:camerakit/CameraKitView.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr_data_extractor/ocr_data_extractor.dart';

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
      home: const MyTestPage(title: 'Flutter Demo Home Page'),
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
  String body = '';
  List<String> names = [
    'negredo daniel',
    'roux matilde',
    'rizzo sophia',
    'richard charlie',
    'pellegrino ximena',
    'pellegrini noah',
    'morelli daniel',
    'mancini ava',
    'morel mariana',
    'alves noah',
    'amato rosalie',
    'banderas lilian',
    'bianchi elijah',
    "RODRIGUES HUGO",
    "FERREIRA LEO",
    "JESUS PABLO",
    "BIANCO CHARLIE",
    "BROWN OLIVIA",
    "BONNET GIORGIA",
    "BONNET MILA",
    "BERTRAND MARIA",
    "BERNARD JACK",
    "ANDRE ANA",
    "Aref Alizadeh",
    "Bruno Logan",
    "CLARKE HUGO",
    "SARAH BISHOP",
    "SOUSA MARTIN",
    "PEREIRA GABRIEL",
  ];

  Future<void> _getNumbers() async {
    setState(() => body = '');
    final pickedFile = await _picker.getImage(source: ImageSource.gallery, imageQuality: 50);
    List<String> numbers = await OCRController().getNumberList(pickedFile!.path);
    setState(() => body = OCRController().sortedResult);
  }

  Future<void> _getNames() async {
    setState(() => body = '');
    final pickedFile = await _picker.getImage(source: ImageSource.gallery, imageQuality: 50);
    print("path is : ${pickedFile!.path}");
    dynamic passengers = await OCRController().getNamesList(pickedFile.path, names, 2);
    setState(() => body = OCRController().sortedResult);
  }

  Future<void> _getPassengers() async {
    setState(() => body = '');
    final pickedFile = await _picker.getImage(source: ImageSource.gallery, imageQuality: 50);
    print("path is : ${pickedFile!.path}");
    dynamic passengers = await OCRController().getPassengerList(pickedFile.path, names);
    setState(() => body = OCRController().sortedResult);
  }

  Future<void> _takePicture() async {
    setState(() => body = '');
    String? path = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => _TakePicture()));
    if (path?.isNotEmpty ?? false) {
      dynamic passengers = await OCRController().getPassengerList(path!, names);
      setState(() => body = OCRController().sortedResult);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Container(padding: const EdgeInsets.all(20), child: SingleChildScrollView(child: Text(body))),
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
