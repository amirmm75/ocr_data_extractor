import 'package:example/consts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ocr_data_extractor/ocr_data_extractor.dart';
import 'package:ocrkit/OCRKitController.dart';
import 'package:ocrkit/OCRKitView.dart';
import 'classes.dart';

class LiveScan extends StatefulWidget {
  const LiveScan({Key? key}) : super(key: key);

  @override
  State<LiveScan> createState() => _LiveScanState();
}

class _LiveScanState extends State<LiveScan> {
  OCRKitController oc = OCRKitController();
  bool loading = false;
  bool isPaused = false;
  List<BackUpOCRPassenger> pPaxes = [];
  List<Map<String, dynamic>> ocrInputs = [];
  List<BackUpOCRPassenger> backedUpPaxes = [];

  @override
  void initState() {
    for (String s in StaticLists.names2) {
      String name = s.trim();
      pPaxes.add(BackUpOCRPassenger(
          name: name,
          fName: name.split(" ").first,
          lName: name.split(" ").last,
          seat: '',
          seq: 0,
          bag: '',
          count: '',
          weight: ''));
    }
    super.initState();
  }

  onTextRead(barcode, values, orientation) {
    // try {
    // Stopwatch stopwatch = Stopwatch()..start();
    // stopwatch.stop();
    // print('Time: ${stopwatch.elapsed}');
    orientation ??= 3;
    Map<String, dynamic> input = {"text": barcode, "orientation": orientation, "values": values};
    print(input);
    print('+');
    ocrInputs.add(input);
    if (!loading) {
      print('start');
      loading = true;
      processOCR();
    }
    // } catch (e, stackTrace) {
    //   print("OnTextRead: $e");
    //   print("StackTrace: $stackTrace");
    // }
  }

  processOCR() {
    Map<String, dynamic> input = ocrInputs.first;
    Stopwatch stopwatch = Stopwatch()..start();
    // stopwatch.stop();
    print('Time1: ${stopwatch.elapsed}');
    OCRController()
        .getPassengerListByOCRData(input, StaticLists.names2)
        .then((List<Map<String, dynamic>> passengers) {
      List<BackUpOCRPassenger> bup =
          passengers.map((e) => BackUpOCRPassenger.fromJson(e)).toList();
      List<BackUpOCRPassenger> pl = [];
      for (var element in bup) {
        List<BackUpOCRPassenger> matchPaxes = pPaxes
            .where((pp) =>
                pp.name.toLowerCase().contains(element.fName.toLowerCase()) &&
                pp.name.toLowerCase().contains(element.lName.toLowerCase()) &&
                element.name.toLowerCase().contains(pp.fName.toLowerCase()) &&
                element.name.toLowerCase().contains(pp.lName.toLowerCase()))
            .toList();
        if (matchPaxes.isNotEmpty) {
          BackUpOCRPassenger pCopy = matchPaxes.first;
          pCopy.seq = element.seq;
          pCopy.seat = element.seat;
          pCopy.weight = element.weight;
          pl.add(pCopy);
        }
      }
      backedUpPaxes = (backedUpPaxes + pl).toSet().toList();
      setState(() {});
      ocrInputs.removeAt(0);
      print("-");
      if (ocrInputs.isEmpty) {
        loading = false;
        print('end');
      } else {
        processOCR();
      }
      stopwatch.stop();
      print('Time3: ${stopwatch.elapsed}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text("Scanner (${backedUpPaxes.length})"), actions: [
        IconButton(
            onPressed: () {
              if (isPaused) {
                oc.resumeCamera();
                setState(() => isPaused = false);
              } else {
                oc.pauseCamera();
                setState(() => isPaused = true);
              }
            },
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause)),
        IconButton(
            onPressed: () {
              Get.dialog(
                      ConfirmFoundPaxesDialog(foundPaxes: [...backedUpPaxes]))
                  .then((value) {
                if (value != null && value is List<BackUpOCRPassenger>) {
                  backedUpPaxes = value;
                  setState(() {});
                }
              });
            },
            icon: const Icon(Icons.sticky_note_2)),
      ]),
      backgroundColor: Colors.white,
      body: Center(
        child: OCRKitView(
            isTakePictureMode: false,
            isScanningText: true,
            onTextRead: (barcode, values, path, orientation) =>
                onTextRead(barcode, values, orientation),
            ocrKitController: oc,
            onPermissionDenied: () {}),
      ),
    );
  }
}

class ConfirmFoundPaxesDialog extends StatefulWidget {
  final List<BackUpOCRPassenger> foundPaxes;

  const ConfirmFoundPaxesDialog({Key? key, required this.foundPaxes})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ConfirmFoundPaxesDialogState();
  }
}

class _ConfirmFoundPaxesDialogState extends State<ConfirmFoundPaxesDialog> {
  List<BackUpOCRPassenger> tmpFoundPaxes = [];

  @override
  void initState() {
    tmpFoundPaxes = widget.foundPaxes;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 10.0,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      insetPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
      backgroundColor: Colors.white,
      content: dialogContent(context),
    );
  }

  dialogContent(BuildContext context) {
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: SizedBox(
          width: Get.width * 0.85,
          height: Get.height * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                "Found Passengers",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                  child: ListView.builder(
                      itemCount: tmpFoundPaxes.length,
                      itemBuilder: (c, i) => FoundPaxWidget(
                            p: tmpFoundPaxes[i],
                            onDelete: () {
                              setState(() {
                                tmpFoundPaxes.removeAt(i);
                              });
                            },
                            seatError: tmpFoundPaxes
                                    .where((element) =>
                                        element.seat == tmpFoundPaxes[i].seat)
                                    .length >
                                1,
                          ))),
              Row(
                children: <Widget>[
                  const SizedBox(width: 12),
                  Expanded(
                    child: RaisedButton(
                      color: Colors.grey,
                      child: const Center(
                          child: Text("Cancel",
                              style: TextStyle(color: Colors.white))),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RaisedButton(
                      color: Colors.green,
                      child: const Center(
                          child: Text("Confirm",
                              style: TextStyle(color: Colors.white))),
                      onPressed: () => Navigator.pop(context, tmpFoundPaxes),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              )
            ],
          ),
        ));
  }
}

class FoundPaxWidget extends StatelessWidget {
  final BackUpOCRPassenger p;
  final Function onDelete;
  final bool seatError;

  const FoundPaxWidget(
      {Key? key,
      required this.p,
      required this.onDelete,
      required this.seatError})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(width: 1, color: Colors.grey))),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(p.seq.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(p.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            p.seat,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: seatError ? Colors.red : Colors.black),
          ),
          const SizedBox(width: 8),
          IconButton(
              onPressed: () => onDelete(),
              icon: const Icon(Icons.remove_circle, color: Colors.red))
        ],
      ),
    );
  }
}
