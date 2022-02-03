import 'dart:async';
import 'dart:convert';
import 'package:ocrkit/OCRKitController.dart';
import 'package:string_similarity/string_similarity.dart';
import 'classes.dart';

class OCRController {
  OCRController._();

  static final OCRController _instance = OCRController._();

  factory OCRController() => _instance;

  final OCRKitController occ = OCRKitController();
  String sortedResult = '';
  String spaceBetweenWords = '';
  bool isSortComplete = false;

  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
  ///***** ***** ***** ***** ***** [FUNCTIONS TO USE AND CALL] ***** ***** ***** ***** *****
  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

  //this function extracts list of names of users
  //extracts last names next to their first names and removes possible icon read like 'i'
  //if inputNames is empty the function finds the names itself with a lot of problems and needs verticalSort
  //if inputNames is not empty, the first and last names found in this list will be returned.
  //valid item in the inputNames list: "amir mehdizadeh"
  Future<List<String>> getNamesList(String path, List<String> inputNames) async {
    final result = await occ.processImageFromPathWithoutView(path);
    if (result.toString().isEmpty) return [];
    Map<String, dynamic> data = jsonDecode(result);
    List<Line>? lines = await initialize(data);
    String horizontalSort = await initSort(lines);
    List<String> finalResult = await findPassengers(horizontalSort, inputNames);
    return finalResult;
  }

  //this function extracts all numbers of an image which have 6 or more digits
  //removes time and date
  Future<List<String>> getNumberList(String path) async {
    final result = await occ.processImageFromPathWithoutView(path);
    if (result.toString().isEmpty) return [];
    Map<String, dynamic> data = jsonDecode(result);
    List<Line>? lines = await initialize(data);
    List<String> finalResult = await findFlightTags(lines);
    return finalResult;
  }

  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
  ///***** ***** ***** ***** ***** [INITIAL AND USEFUL FUNCTIONS] ***** ***** ***** *****
  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

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

  //Same line Check! //So important and useful
  //strictness can be hard or medium //first is more accurate and second is more sensitive
  bool isInTheSameLine(Line l1, Line l2, Strictness strictness) {
    bool isInSameLines = true;
    //this is more accurate
    if (strictness == Strictness.hard) {
      var i1 = (l1.cornerList![0].x + l1.cornerList![2].x) / 2;
      var i2 = (l2.cornerList![0].x + l2.cornerList![2].x) / 2;
      if (i1 < l2.cornerList![0].x ||
          i1 > l2.cornerList![2].x ||
          i2 < l1.cornerList![0].x ||
          i2 > l1.cornerList![2].x) isInSameLines = false;
    } else if (l1.cornerList![0].x >
            l2.cornerList![2].x - 10 || //strictness == Strictness.medium, more sensitive
        l1.cornerList![2].x < l2.cornerList![0].x + 10) {
      //this is the first and the most important layer of filter
      isInSameLines = false;
    }
    if (l1.cornerList![0].y < l2.cornerList![2].y && l1.cornerList![2].y > l2.cornerList![0].y) {
      //if they have any horizontal sharing in space they must not be in the same line
      isInSameLines = false;
    }
    if ((l1.cornerList![2].x - l1.cornerList![0].x) > 2 * (l2.cornerList![2].x - l2.cornerList![0].x) ||
        (l2.cornerList![2].x - l2.cornerList![0].x) > 2 * (l1.cornerList![2].x - l1.cornerList![0].x)) {
      //sometimes a really big font is near a small font which doesn't mean they meant to be in the same line
      isInSameLines = false;
    }
    return isInSameLines;
  }

  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
  ///***** ***** ***** ***** ***** [SORTING ALGORITHM] ***** ***** ***** ***** *****
  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

  //Sorts all lines
  //probably the most accurate algorithm for sorting lines
  //the length of space between words of a line is 4 and it's changeable!
  initSort(List<Line>? allLines, {int spaceBetweenWordsCount = 4}) async {
    isSortComplete = false;
    sortedResult = '';
    spaceBetweenWords = '';
    for (int i = 0; i < spaceBetweenWordsCount; i++) {
      spaceBetweenWords = spaceBetweenWords + ' ';
    }
    sortLines(allLines, spaceBetweenWords);
    await waitWhile(() => isSortComplete);
    return sortedResult; //the data is ready to use!
  }

  Future waitWhile(bool Function() test, [Duration pollInterval = Duration.zero]) {
    var completer = Completer();
    check() {
      if (test()) {
        completer.complete();
      } else {
        Timer(pollInterval, check);
      }
    }

    check();
    return completer.future;
  }

  sortLines(List<Line>? lines, String spaceBetweenWords) {
    //add entireLines
    if (lines == null || lines.isEmpty) {
      isSortComplete = true;
    } else {
      List<Line> sameLines = [];
      Line firstLine = leastXFinder(lines);
      sameLines.add(firstLine);
      lines.removeWhere((element) => element == firstLine);
      findSameLines(lines, sameLines, spaceBetweenWords);
    }
  }

  findSameLines(List<Line> allLines, List<Line> sameLines, String spaceBetweenWords) {
    Line newLine = Line();
    bool isInSameLines = true;
    // is newLine in same lines?
    if (allLines.isEmpty) {
      isInSameLines = false;
    } else {
      newLine = leastXFinder(allLines);
      for (var element in sameLines) {
        if (!isInTheSameLine(newLine, element, Strictness.hard)) isInSameLines = false;
      }
    }
    // yes? find same lines again, no? sort lines again
    if (isInSameLines) {
      sameLines.add(newLine);
      allLines.removeWhere((element) => element == newLine);
      findSameLines(allLines, sameLines, spaceBetweenWords);
    } else {
      List<Line> sortedLines = [];
      String result = sortedResult;
      int lastI = sameLines.length;
      for (int i = 0; i < lastI; i++) {
        Line maxY = sameLines
            .reduce((value, element) => value.cornerList![0].y > element.cornerList![0].y ? value : element);
        sortedLines.add(maxY);
        sameLines.removeWhere((element) => element == maxY);
      }
      for (var element in sortedLines) {
        result = result + element.text! + spaceBetweenWords;
      }
      sortedResult = result + "\n";
      sortLines(allLines, spaceBetweenWords);
    }
  }

  leastXFinder(List<Line> lines) {
    Line firstLine =
        lines.reduce((value, element) => value.cornerList![0].x < element.cornerList![0].x ? value : element);
    return firstLine;
  }

  /// ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
  /// ***** ***** ***** ***** ***** [ALL FINDING ALGORITHMS] ***** ***** ***** ***** *****
  /// ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

  //find Flight Tags
  Future<List<String>> findFlightTags(List<Line>? lines) async {
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

  //find passengers
  Future<List<String>> findPassengers(String horizontalSort, List<String> inputNames) async {
    try {
      List<String> names = <String>[];
      List<String> lines = horizontalSort.split("\n");
      for (String l in lines) {
        if (l.split(spaceBetweenWords).length > 2) {
          String s = l.trim();
          //remove the possible i from the first
          if (s.startsWith("i ") && !s.startsWith("i  ")) s = s.substring(2);
          List<String> items = s.split(spaceBetweenWords);
          //searching among input names
          if (inputNames.isNotEmpty) {
            String nameInLine = items[1] + ' ' + items[2];
            BestMatch bestMatch = nameInLine.bestMatch(inputNames);
            if ((bestMatch.bestMatch.rating ?? 0) > 0.8) {
              names.add(s.replaceFirst(items[1] + spaceBetweenWords + items[2],
                  bestMatch.bestMatch.target ?? items[1] + spaceBetweenWords + items[2]));
            }
          } else {
            //this needs work
            //without inputNames no item will add
          }
        }
      }
      //names now contain corrected names with other data we should extract!
      //we return processed output here as a List<String>
      return names;
    } catch (e) {
      return [];
    }
  }
}
