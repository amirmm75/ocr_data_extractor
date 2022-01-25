import 'dart:convert';
import 'package:ocrkit/OCRKitController.dart';
import 'classes.dart';

class OCRController {
  OCRController._();

  static final OCRController _instance = OCRController._();

  factory OCRController() => _instance;

  final OCRKitController occ = OCRKitController();

  //this function extracts all numbers of an image which have 6 or more digits
  //removes time and date
  Future<List<String>> getNumberList(String path) async {
    final result = await occ.processImageFromPathWithoutView(path);
    if (result.toString().isEmpty) return [];
    Map<String, dynamic> data = jsonDecode(result);
    List<Line>? lines = await initialize(data);
    List<String> finalResult = await findTags(lines);
    return finalResult;
  }

  //extracts each every word
  Future<List<Line>?> initialize(Map<String, dynamic> output) async {
    dynamic sentValue = output["values"];
    int orientation = int.parse(output["orientation"].toString());
    // String path = output["path"];
    // String text = output["text"];
    // mhc.resetPicListDeletePics(path);
    if (sentValue == null) {
      return [];
    } else {
      var data = {"items": jsonDecode(sentValue)};
      Object obj = Object.fromJson(data);
      List<Line>? lines = [];
      if (orientation == 0) {
        Line maxXLine = obj.lines!
            .reduce((value, element) => value.cornerList![2].x > element.cornerList![2].x ? value : element);
        var maxX = maxXLine.cornerList![2].x;
        for (var element in obj.lines!) {
          Line line = Line(
            text: element.text,
            cornerList: [
              CornerPoint(x: element.cornerList![0].y, y: maxX - element.cornerList![0].x),
              CornerPoint(x: element.cornerList![1].y, y: maxX - element.cornerList![1].x),
              CornerPoint(x: element.cornerList![2].y, y: maxX - element.cornerList![2].x),
              CornerPoint(x: element.cornerList![3].y, y: maxX - element.cornerList![3].x)
            ],
          );
          lines.add(line);
        }
      } else {
        lines = obj.lines;
      }
      return lines;
    }
  }

  //find Flight Tags
  Future<List<String>> findTags(List<Line>? lines) async {
    try {
      List<String> tags = <String>[];
      lines?.forEach((l) {
        String s = l.text!
            .trim()
            .toUpperCase()
            .replaceAll(" ", "")
            .replaceAll("O", "0")
            .replaceAll("L", "1")
            .replaceAll("I", "1")
            .replaceAll("T", "1")
            .replaceAll('Z', '2')
            .replaceAll("G", "9")
            .replaceAll(RegExp(r'[^0-9]'), '');
        if (s.length > 5 && !(l.text?.contains("/") ?? false) && !(l.text?.contains(".") ?? false)) {
          tags.add(s);
        }
      });
      //we return processed output here as a List<String>
      return tags;
    } catch (e) {
      return [];
    }
  }
}
