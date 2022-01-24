import 'dart:convert';
import 'package:ocrkit/OCRKitController.dart';
import 'classes.dart';

class OCRController {
  OCRController._();

  static final OCRController _instance = OCRController._();

  factory OCRController() => _instance;

  //use this
  Future<List<String>> processImageWithOCR(String path) async {
    final result = await OCRKitController().processImageFromPathWithoutView(path);
    if (result.toString().isEmpty) return [];
    Map<String, dynamic> data = jsonDecode(result);
    List<String> finalResult = await processOutput(data);
    return finalResult;
  }

  Future<List<String>> processOutput(Map<String, dynamic> output) async {
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
      List<String> finalResult = await findTags(lines);
      return finalResult;
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
