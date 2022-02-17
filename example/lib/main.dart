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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> values = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _getNumbers() async {
    final pickedFile =
        await _picker.getImage(source: ImageSource.gallery, imageQuality: 50);
    List<String> numbers =
        await OCRController().getNumberList(pickedFile!.path);
  }

  Future<void> _getNames() async {
    final pickedFile =
        await _picker.getImage(source: ImageSource.gallery, imageQuality: 50);
    print("path is : ${pickedFile!.path}");
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
      'bianchi elijah'
    ];
    List<String> names2 = [
      'BURALE AHMEDMOHAMED',
      'AHMED CUDONHAJI',
      'ADAN XALIMOIBRAHIM',
      'BARKHAD AXLAAMYASIN',
      'ABDULLA OMARMOHAMED',
      'CABDILAHI SAWDAKALI',
      'DALMAR JIBRILDAHIR',
      'HABARWA RAGEKASE',
      'HASAN ABDIRAHMANMOHAMED',
      'HASAN KADIJAIBRAHIM',
      'HASAN HUSENSAI',
      'HERSI ISMAILMOHAMED',
    ];
    dynamic passengers =
        await OCRController().getNamesList(pickedFile.path, names, 1);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: ListView(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).

          children: values
              .map(
                  (e) => SizedBox(height: 50, width: Get.width, child: Text(e)))
              .toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getNames,
        child: const Icon(Icons.ac_unit),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}