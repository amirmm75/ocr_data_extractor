import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:ocrkit/OCRKitController.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:string_validator/string_validator.dart';
import 'classes.dart';

class OCRController {
  OCRController._();

  static final OCRController _instance = OCRController._();

  factory OCRController() => _instance;

  final OCRKitController occ = OCRKitController();
  String googleText = '';
  String sortedResult = '';
  String sortedResultYAxis = '';
  String sortedResultXAxis = '';
  String sortedResultSlope = '';
  String sortedResultVertical = '';
  String spaceBetweenWords = '';
  String spaceBetweenWordsVertical = '';
  List<Line> beforeLines = [];
  List<Line> afterLines = [];
  int averageLineLength = 0;
  bool waitComplete = false;
  bool isSortComplete = true;
  bool isSortCompleteVertical = true;

  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
  ///***** ***** ***** ***** ***** [FUNCTIONS_TO_USE_AND_CALL] ***** ***** ***** ***** *****
  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

  ///this function extracts list of names of users
  ///extracts last names next to their first names and removes possible icon read like 'i'
  ///if inputNames is empty the function finds the names itself with a lot of problems and needs verticalSort
  ///if inputNames is not empty, the first and last names found in this list will be returned.
  ///valid item in the inputNames list: "amir mehdizadeh".
  ///we use remove from top to removes extra words! example: " seat ", don't forget the space!
  ///Strictness = 0 : medium & Strictness = 1 : hard & alternative hard = 2
  Future<List<Map<String, dynamic>>> getNamesList(
      String path, List<String> inputNames, int strictness) async {
    final result = await occ.processImageFromPathWithoutView(path);
    if (result.toString().isEmpty) return [];
    Map<String, dynamic> data = jsonDecode(result);
    List<Line>? lines = await initialize(data,
        removeFromTopWords: [" seat ", " type ", " name "], removeFromTopWords2: [" date:", " gate:"]);
    List<Line>? lines2 = [...lines!];
    String horizontalSort = await initSort(lines, spaceBetweenWordsCount: 1, strictness: strictness);
    List<Map<String, dynamic>> finalResult = await findPassengers(horizontalSort, lines2, inputNames);
    return finalResult;
  }

  ///this function extracts all numbers of an image which have 6 or more digits
  ///removes time and date
  Future<List<String>> getNumberList(String path) async {
    final result = await occ.processImageFromPathWithoutView(path);
    if (result.toString().isEmpty) return [];
    Map<String, dynamic> data = jsonDecode(result);
    List<Line>? lines = await initialize(data);
    List<String> finalResult = await findFlightTags(lines);
    return finalResult;
  }

  ///this function extracts list of data of passengers of a brs flight table.
  Future<List<Map<String, dynamic>>> getPassengerList(String path, List<String> inputNames) async {
    final result = await occ.processImageFromPathWithoutView(path);
    if (result.toString().isEmpty) return [];
    Map<String, dynamic> data = jsonDecode(result);
    List<Line>? lines = await initialize(data);
    Object o1 = Object(lines: lines);
    beforeLines = Object.fromJson(o1.toJson()).lines ?? [];
    List<Line>? disableSlopeLines = await disableSlope(lines);
    Object o2 = Object(lines: disableSlopeLines);
    afterLines = Object.fromJson(o2.toJson()).lines ?? [];
    List<Map<String, dynamic>> finalResult = await extractPassengersData(disableSlopeLines ?? [], inputNames);
    return finalResult;
  }

  ///this function extracts list of data of passengers of a brs flight table.
  Future<List<Map<String, dynamic>>> getPassengerListByOCRData(
      Map<String, dynamic> data, List<String> inputNames) async {
    if (data.isEmpty) return [];
    List<Line>? lines = await initialize(data);
    Object o1 = Object(lines: lines);
    beforeLines = Object.fromJson(o1.toJson()).lines ?? [];
    List<Line>? disableSlopeLines = await disableSlope(lines);
    Object o2 = Object(lines: disableSlopeLines);
    afterLines = Object.fromJson(o2.toJson()).lines ?? [];
    List<Map<String, dynamic>> finalResult = await extractPassengersData(disableSlopeLines ?? [], inputNames);
    return finalResult;
  }

  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
  ///***** ***** ***** ***** ***** [INITIAL_AND_USEFUL_FUNCTIONS] ***** ***** ***** *****
  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

  ///extracts each every word
  ///has a feature that takes a list of String (removeFromTopWords) and finds out which one of them is the
  /// highest and removes the upper words! removeFromTopWords2 removes the words themselves too.
  ///example of a valid list: [" name ", " seat ", " type "]. don't forget the space!
  Future<List<Line>?> initialize(Map<String, dynamic> output,
      {List<String> removeFromTopWords = const [], List<String> removeFromTopWords2 = const []}) async {
    dynamic sentValue = output["values"];
    int orientation = int.parse(output["orientation"].toString());
    // String path = output["path"];
    googleText = output["text"];
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
      } else if (orientation == 5) {
        for (var element in obj.lines!) {
          Line line = Line(
            text: element.text,
            cornerList: [
              CornerPoint(x: element.cornerList![3].x, y: element.cornerList![3].y),
              CornerPoint(x: element.cornerList![0].x, y: element.cornerList![0].y),
              CornerPoint(x: element.cornerList![1].x, y: element.cornerList![1].y),
              CornerPoint(x: element.cornerList![2].x, y: element.cornerList![2].y),
            ],
          );
          lines.add(line);
        }
      } else {
        ///orientation here is 3
        lines = obj.lines;
      }
      // if (removeFromTopWords.isNotEmpty || removeFromTopWords2.isNotEmpty) {
      //   double minX = 0;
      //   double maxX = 0;
      //   for (Line l in lines!) {
      //     for (String s in removeFromTopWords) {
      //       if (" ${l.text!} ".toLowerCase().contains(s.toLowerCase())) {
      //         if (l.cornerList![0].x < minX || minX == 0) {
      //           minX = l.cornerList![0].x + 0.1;
      //         }
      //       }
      //     }
      //     for (String s in removeFromTopWords2) {
      //       if (" ${l.text!} ".toLowerCase().contains(s.toLowerCase())) {
      //         if (l.cornerList![2].x > maxX) maxX = l.cornerList![2].x + 0.1;
      //       }
      //     }
      //   }
      //   if (maxX > minX) minX = maxX;
      //   if (minX != 0) {
      //     for (int i = lines.length - 1; i >= 0; i--) {
      //       Line l = lines[i];
      //       if (l.cornerList![2].x <= minX) {
      //         lines.removeWhere((e) => e == l);
      //       }
      //     }
      //   }
      // }
      List<int> lengths = [];
      for (var e in lines!) {
        if (!lengths.contains(e.text!.length)) {
          lengths.add(e.text!.length);
        }
      }
      lengths.sort((a, b) => a.compareTo(b));
      int i = lengths.length ~/ 2;
      averageLineLength = lengths[(i > 5 ? i - 1 : i)];
      return lines;
    }
  }

  ///Finds a Line which is the closets to the line from the right side.
  ///for example we can use it when we have the first name and we want to extract the last name on the right of it.
  Line findClosetLine(Line line, List<Line> allLines) {
    allLines.removeWhere((element) => element.cornerList![3].x <= line.cornerList![0].x);
    allLines.removeWhere((element) => element.cornerList![0].x > line.cornerList![3].x);
    allLines.removeWhere((element) => element.cornerList![0].y > line.cornerList![3].y);
    if (allLines.isEmpty) return Line(text: "");
    Line result = allLines.reduce((a, b) {
      var ax = a.cornerList![0].x - line.cornerList![1].x;
      var ay = a.cornerList![0].y - line.cornerList![1].y;
      var bx = b.cornerList![0].x - line.cornerList![1].x;
      var by = b.cornerList![0].y - line.cornerList![1].y;
      return (ax * ax + ay * ay * 4 < bx * bx + by * by * 4) ? a : b;
    });
    return result;
  }

  ///Finds a Line which is the closets to the line from the bottom.
  Line findClosetLineVertical(Line line, List<Line> allLines, {bool fromBot = true}) {
    allLines.removeWhere((element) => element.cornerList![0].y <= line.cornerList![1].y);
    allLines.removeWhere((element) => element.cornerList![1].y > line.cornerList![0].y);
    if (fromBot) {
      allLines.removeWhere((element) => element.cornerList![0].x < line.cornerList![0].x);
    }
    if (allLines.isEmpty) return Line(text: "");
    Line result = allLines.reduce((a, b) {
      var ax = a.cornerList![0].x - line.cornerList![3].x;
      var ay = a.cornerList![0].y - line.cornerList![3].y;
      var bx = b.cornerList![0].x - line.cornerList![3].x;
      var by = b.cornerList![0].y - line.cornerList![3].y;
      return (ax * ax * 4 + ay * ay < bx * bx * 4 + by * by) ? a : b;
    });
    return result;
  }

  ///takes a String (line) which is a line and contains a list of Strings joined with space and each one of
  ///them much validate. if most of them returned true then the function must return true
  bool validateFeatureInLine(String line, double percent, bool Function(String) validate) {
    int truth = 0;
    int all = 0;
    List<String> elements = line.trim().split(' ');
    for (String e in elements) {
      all++;
      if (validate(e)) truth++;
    }
    // print("truth: ${truth}");
    // print("all: ${all}");
    // print("Percent: ${truth / all * 100}");
    return truth / all * 100 > percent;
  }

  ///Same line Check! //So important and useful
  ///strictness can be hard or medium //the first is more accurate and second one is more sensitive
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
    if ((l1.cornerList![2].x - l1.cornerList![0].x) > 3 * (l2.cornerList![2].x - l2.cornerList![0].x) ||
        (l2.cornerList![2].x - l2.cornerList![0].x) > 3 * (l1.cornerList![2].x - l1.cornerList![0].x)) {
      //sometimes a really big font is near a small font which doesn't mean they meant to be in the same line
      isInSameLines = false;
    }
    return isInSameLines;
  }

  ///Checks if words are vertically in the same Column! //So important and useful
  bool isInTheSameColumn(Line l1, Line l2, Strictness strictness) {
    bool isInSameLines = true;
    //this is more accurate
    if (strictness == Strictness.hard) {
      var i1 = (l1.cornerList![0].y + l1.cornerList![2].y) / 2;
      var i2 = (l2.cornerList![0].y + l2.cornerList![2].y) / 2;
      if (i1 > l2.cornerList![0].y ||
          i1 < l2.cornerList![2].y ||
          i2 > l1.cornerList![0].y ||
          i2 < l1.cornerList![2].y) {
        isInSameLines = false;
      }
    } else if (l1.cornerList![0].y < l2.cornerList![2].y || //strictness == Strictness.medium, more sensitive
        l1.cornerList![2].y > l2.cornerList![0].y) {
      //this is the first and the most important layer of filter
      isInSameLines = false;
    }
    if (l1.cornerList![0].x < l2.cornerList![2].x && l1.cornerList![2].x > l2.cornerList![0].x) {
      //if they have any vertical sharing in space they must not be in the same line
      isInSameLines = false;
    }
    if ((l1.cornerList![2].x - l1.cornerList![0].x) > 3 * (l2.cornerList![2].x - l2.cornerList![0].x) ||
        (l2.cornerList![2].x - l2.cornerList![0].x) > 3 * (l1.cornerList![2].x - l1.cornerList![0].x)) {
      //sometimes a really big font is near a small font which doesn't mean they meant to be in the same line
      isInSameLines = false;
    }
    return isInSameLines;
  }

  ///Considers the slope for checking being in the Same line
  ///uses the average slope of both lines
  bool isInTheSameSlope(Line l1, Line l2, {var limit = 40}) {
    // print("***** ***** *****");
    // print(l1.text);
    // print("${l1.cornerList![0].y} ${l1.cornerList![0].x}");
    // print("${l1.cornerList![1].y} ${l1.cornerList![1].x}");
    // print("${l1.cornerList![2].y} ${l1.cornerList![2].x}");
    // print("${l1.cornerList![3].y} ${l1.cornerList![3].x}");
    // print(l2.text);
    // print("${l2.cornerList![0].y} ${l2.cornerList![0].x}");
    // print("${l2.cornerList![1].y} ${l2.cornerList![1].x}");
    // print("${l2.cornerList![2].y} ${l2.cornerList![2].x}");
    // print("${l2.cornerList![3].y} ${l2.cornerList![3].x}");
    //l1 must be the left one. if not? => swap
    if (l1.cornerList![1].y < l2.cornerList![1].y) {
      Line temp = l2;
      l2 = l1;
      l1 = temp;
    }
    //first calculate the average slope
    var s1 = slopeOfLine(l1);
    var s2 = slopeOfLine(l2);
    var s3 = (s1 + s2) / 2;
    var addingHeight = s3 *
        (((l1.cornerList![1].y + l1.cornerList![2].y) / 2) -
            ((l2.cornerList![1].y + l2.cornerList![2].y) / 2));
    var distance = addingHeight +
        ((l2.cornerList![1].x + l2.cornerList![2].x) / 2) -
        ((l1.cornerList![1].x + l1.cornerList![2].x) / 2);
    //distance of lines can't be negative or it will cause the true result!
    distance = distance < 0 ? -distance : distance;
    return (distance < limit);
  }

  ///this function returns the slope of a single word
  ///this can be very useful
  slopeOfLine(Line l) {
    var xRight = (l.cornerList![1].x + l.cornerList![2].x) / 2;
    var yRight = (l.cornerList![1].y + l.cornerList![2].y) / 2;
    var xLeft = (l.cornerList![0].x + l.cornerList![3].x) / 2;
    var yLeft = (l.cornerList![0].y + l.cornerList![3].y) / 2;
    var slope = (xLeft - xRight) / (yLeft - yRight);
    return slope;
  }

  ///this function gets line list and removes the slope
  ///handles problem of rotated images
  Future<List<Line>?> disableSlope(List<Line>? lines) async {
    try {
      var minx = 0.0;
      var miny = 0.0;
      var slopeSum = 0.0;
      int slopeCount = 0;
      for (var l in lines!) {
        if (l.text!.length > averageLineLength) {
          slopeSum = slopeSum + slopeOfLine(l);
          slopeCount++;
        }
      }
      if (slopeCount == 0) return lines;
      var tan = slopeSum / slopeCount; //average of slopes
      var cos2 = 1 / (1 + tan * tan);
      var sin2 = (tan * tan) * cos2;
      var cos = sqrt(cos2);
      var sin = sqrt(sin2);
      //negative the angle(it should rotate back to get into x axis.)
      if (tan > 0) {
        sin = -sin;
      }
      if (cos == 0) return lines;

      ///Rotate formula
      ///x' = x cos - y sin
      ///y' = x sin + y cos
      // var maxx = 0;
      // var maxy = 0;
      // for (Line l in lines) {
      //   if (l.cornerList![0].x > maxx) {
      //     maxx = l.cornerList![0].x;
      //   }
      //   if (l.cornerList![0].y > maxy) {
      //     maxy = l.cornerList![0].y;
      //   }
      // }
      for (Line l in lines) {
        for (int i = 0; i < l.cornerList!.length; i++) {
          var x = -1 * l.cornerList![i].y;
          var y = -1 * l.cornerList![i].x;
          // var x = maxy - l.cornerList![i].y;
          // var y = maxx - l.cornerList![i].x;
          var xx = x * cos - y * sin;
          var yy = x * sin + y * cos;
          l.cornerList![i].x = -1 * yy;
          l.cornerList![i].y = -1 * xx;
          if (l.cornerList![i].x < minx) minx = l.cornerList![i].x;
          if (l.cornerList![i].y < miny) miny = l.cornerList![i].y;
        }
      }
      // for (Line l in lines) {
      //   if (l.cornerList![0].x < minx) {
      //     minx = l.cornerList![0].x;
      //   }
      //   if (l.cornerList![0].y < miny) {
      //     miny = l.cornerList![0].y;
      //   }
      // }
      // for (Line l in lines) {
      //   for (int i = 0; i < l.cornerList!.length; i++) {
      //     l.cornerList![i].x = l.cornerList![i].x - minx;
      //     l.cornerList![i].y = l.cornerList![i].y - miny;
      //   }
      // }
      if (minx < 0 || miny < 0) {
        for (Line l in lines) {
          for (int i = 0; i < l.cornerList!.length; i++) {
            l.cornerList![i].x = l.cornerList![i].x - minx;
            l.cornerList![i].y = l.cornerList![i].y - miny;
          }
        }
      }
      return lines;
    } catch (e) {
      print(e);
      return lines;
    }
  }

  ///checks if two strings are similar or not.
  ///WillDo: gives a percentage
  checkSimilarity(String s1, String s2, {bool caseSensitive = false}) {
    if (!caseSensitive) {
      s1 = s1.toLowerCase();
      s2 = s2.toLowerCase();
    }
    List<String> l1 = s1.trim().split("");
    List<String> l2 = s2.trim().split("");
    int error = 0;
    for (int i = 0; i < (l1.length > l2.length ? l1.length : l2.length); i++) {
      String e1 = l1.length > i ? l1[i] : '';
      String e2 = l2.length > i ? l2[i] : '';
      if (e1 != e2 || e1 == '' || e2 == '') {
        error++;
      }
    }
    return (error < 2) ? true : false;
  }

  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
  ///***** ***** ***** ***** ***** [SORTING_ALGORITHM] ***** ***** ***** ***** *****
  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

  ///Sorts all lines
  ///probably the most accurate algorithm for sorting lines
  ///the length of space between words of a line is 4 and it's changeable!
  initSort(List<Line>? allLines,
      {int spaceBetweenWordsCount = 4, bool isHorizontal = true, int strictness = 1}) async {
    if (isHorizontal) {
      isSortComplete = false;
      sortedResult = '';
    } else {
      isSortCompleteVertical = false;
      sortedResultVertical = '';
    }
    spaceBetweenWords = '';
    for (int i = 0; i < spaceBetweenWordsCount; i++) {
      spaceBetweenWords = spaceBetweenWords + ' ';
    }
    sortLines(allLines, spaceBetweenWords, isHorizontal, strictness);
    await waitWhile(() => isHorizontal ? isSortComplete : isSortCompleteVertical);
    return isHorizontal ? sortedResult : sortedResultVertical; //the data is ready to use!
  }

  ///this is a check that ensures the sort is ended!
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

  ///sorts using recursive! Ends the sort at the end.
  sortLines(List<Line>? lines, String spaceBetweenWords, bool isHorizontal, int strictness) {
    //add entireLines
    if (lines == null || lines.isEmpty) {
      isHorizontal ? isSortComplete = true : isSortCompleteVertical = true;
    } else {
      List<Line> sameLines = [];
      Line firstLine =
          isHorizontal ? leastXFinder(lines, useMiddle: true) : maxYFinder(lines, useMiddle: true);
      sameLines.add(firstLine);
      lines.removeWhere((element) => element == firstLine);
      findSameLines(lines, sameLines, spaceBetweenWords, isHorizontal, strictness);
    }
  }

  ///this finds same line words of the found words.
  findSameLines(List<Line> allLines, List<Line> sameLines, String spaceBetweenWords, bool isHorizontal,
      int strictness) {
    Line newLine = Line();
    bool isInSameLines = true;
    // is newLine in same lines?
    if (allLines.isEmpty) {
      isInSameLines = false;
    } else {
      newLine =
          isHorizontal ? leastXFinder(allLines, useMiddle: true) : maxYFinder(allLines, useMiddle: true);
      if (strictness < 2) {
        for (var element in sameLines) {
          if ((isHorizontal
              ? !isInTheSameLine(newLine, element, strictness == 0 ? Strictness.medium : Strictness.hard)
              : !isInTheSameColumn(newLine, element, Strictness.medium))) {
            isInSameLines = false;
          }
        }
      } else {
        Line element = sameLines.last;
        if ((isHorizontal
            ? !isInTheSameLine(newLine, element, Strictness.hard)
            : !isInTheSameColumn(newLine, element, Strictness.hard))) {
          isInSameLines = false;
        }
      }
    }
    // yes? find same lines again, no? sort lines again
    if (isInSameLines) {
      sameLines.add(newLine);
      allLines.removeWhere((element) => element == newLine);
      findSameLines(allLines, sameLines, spaceBetweenWords, isHorizontal, strictness);
    } else {
      List<Line> sortedLines = [];
      String result = isHorizontal ? sortedResult : sortedResultVertical;
      int lastI = sameLines.length;
      for (int i = 0; i < lastI; i++) {
        Line max = isHorizontal ? maxYFinder(sameLines) : leastXFinder(sameLines);
        // Line maxY = maxYFinder(sameLines);
        // Line maxX = maxXFinder(sameLines);
        sortedLines.add(max);
        sameLines.removeWhere((element) => element == max);
      }
      for (var element in sortedLines) {
        result = result + element.text! + spaceBetweenWords;
      }
      if (isHorizontal) {
        sortedResult = result + "\n";
      } else {
        sortedResultVertical = result + "\n";
      }
      sortLines(allLines, spaceBetweenWords, isHorizontal, strictness);
    }
  }

  ///can find leastX based on the middle height
  leastXFinder(List<Line> lines, {bool useMiddle = false}) {
    Line firstLine = lines.reduce((value, element) {
      var i1 = !useMiddle ? value.cornerList![0].x : (value.cornerList![0].x + value.cornerList![2].x) / 2;
      var i2 =
          !useMiddle ? element.cornerList![0].x : (element.cornerList![0].x + element.cornerList![2].x) / 2;
      return i1 < i2 ? value : element;
    });
    return firstLine;
  }

  ///based on the left part of the word
  maxXFinder(List<Line> lines) {
    Line firstLine =
        lines.reduce((value, element) => value.cornerList![0].x > element.cornerList![0].x ? value : element);
    return firstLine;
  }

  ///based on the left part of the word
  leastYFinder(List<Line> lines) {
    Line firstLine =
        lines.reduce((value, element) => value.cornerList![0].y < element.cornerList![0].y ? value : element);
    return firstLine;
  }

  ///can find maxY based on the middle width
  maxYFinder(List<Line> lines, {bool useMiddle = false}) {
    Line firstLine = lines.reduce((value, element) {
      var i1 = !useMiddle ? value.cornerList![0].y : (value.cornerList![0].y + value.cornerList![2].y) / 2;
      var i2 =
          !useMiddle ? element.cornerList![0].y : (element.cornerList![0].y + element.cornerList![2].y) / 2;
      return i1 > i2 ? value : element;
    });
    return firstLine;
  }

  /// ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
  /// ***** ***** ***** ***** ***** [ALL_FINDING_ALGORITHMS] ***** ***** ***** ***** *****
  /// ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

  ///find Flight Tags
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

  ///find passengers
  Future<List<Map<String, dynamic>>> findPassengers(
      String horizontalSort, List<Line> allLines, List<String> inputNames) async {
    List<String> results = <String>[];
    List<String> searchingNames = <String>[];
    List<String> searchingItems = <String>[];
    List<String> lines = horizontalSort.toLowerCase().split("\n");
    //making lines ready to search
    for (String l in lines) {
      if (l.split(spaceBetweenWords).length > 2) {
        try {
          String s = l.trim();
          //remove the possible icon from the first
          if (s.startsWith("i ") ||
              s.startsWith("↑ ") ||
              s.startsWith("4 ") ||
              s.startsWith("† ") ||
              s.startsWith("İ ") ||
              s.startsWith("é ") ||
              s.startsWith("o ") ||
              s.startsWith("d ") ||
              s.startsWith("+ ")) s = s.substring(2).trim();
          List<String> items = s.split(spaceBetweenWords);
          searchingNames.add(items[0] + ' ' + items[1]);
          searchingItems.add(s);
        } catch (e) {
          //not a valid line
        }
      }
    }
    //without inputNames no item will add
    if (inputNames.isEmpty) return [];
    //searching among input names
    inputNames = inputNames.map((e) => e = e.toLowerCase()).toList();
    for (String n in searchingNames) {
      BestMatch bestMatch = n.bestMatch(inputNames);
      if ((bestMatch.bestMatch.rating ?? 0) > 0.85) {
        int index = searchingNames.indexOf(n);
        String s = searchingItems[index].replaceFirst(n.replaceFirst(" ", spaceBetweenWords),
            bestMatch.bestMatch.target!.replaceFirst(" ", spaceBetweenWords));
        results.add(s);
      }
    }
    List<Map<String, dynamic>> passengers = [];
    for (String n in results) {
      String fullName = '';
      String seat = '';
      String seq = '';
      String bag = '';
      List<String> items = n.split(spaceBetweenWords);
      for (int i = 0; i < items.length; i++) {
        String nextItem = (i == items.length - 1) ? '' : items[i + 1];
        List<dynamic> isSeatFunction = isPassengerSeat(items[i], nextItem);
        if (isSeatFunction[0]) {
          seat = isSeatFunction[1];
          seq = items.sublist(i + 1).firstWhere((e) => isPassengerSequence(e), orElse: () => '');
          if (i < items.length - 2 &&
              seq.length == 1 &&
              seq == items[i + 1] &&
              isPassengerSequence(items[i + 2])) seq = items[i + 2];
          break;
        } else if (isAlpha(items[i]) && i < 3) {
          fullName = fullName + items[i] + ' ';
        }
      }
      bag = items.firstWhere((s) => isPassengerBag(s), orElse: () => '').replaceAll('o', '0');
      fullName = fullName.trim();
      seq = seq.trim();
      OCRPassenger p = OCRPassenger(name: fullName, seat: seat, seq: seq, bag: bag);
      if (seat.isNotEmpty) passengers.add(p.toJson());
    }
    //we return processed output here;
    return passengers;
  }

  ///checks whether name and family have been in inputNames or not.
  ///the first item of the list returned is the bool result and the second is the String result.
  List<dynamic> doesNamesContain2String(String? name, String? family, List<String> inputNames) {
    bool b = false;
    String temp = '';
    name = name!.toLowerCase().trim();
    family = family!.toLowerCase().trim();
    //.replaceAll('8', 'b').replaceAll("0", "o").replaceAll('2', 'z').replaceAll("9", "g")
    if (name.length < 2) return [false, ''];
    for (var s in inputNames) {
      if ("$name $family".contains(s.toLowerCase()) || checkSimilarity("$name $family", s)) {
        b = true;
        temp = s.toLowerCase();
      }
    }
    return [b, temp];
  }

  ///checks whether name and family have been in inputNames or not.
  ///the first item of the list returned is the bool result and the second is the String result.
  List<dynamic> doesNamesContainString(String? string, List<String> inputNames) {
    bool b = false;
    String temp = '';
    string = string!.toLowerCase().trim();
    if (string.length < 2) return [false, ''];
    for (var s in inputNames) {
      if (string.contains(s.toLowerCase()) || checkSimilarity(string, s)) {
        b = true;
        temp = s.toLowerCase();
      }
    }
    return [b, temp];
  }

  ///new function used to extract flight passenger data using input names for a dcs passenger list.
  extractPassengersData(List<Line> lines, List<String> inputNames) async {
    try {
      lines.sort((a, b) => a.cornerList![0].x.compareTo(b.cornerList![0].x));
      List<List<Line>> sortedLines = [[]];
      for (int i = 0; i < lines.length; i++) {
        Line e = lines[i];
        // Line next = i < lines.length - 1 ? lines[i + 1] : Line(text: "");
        Line next = findClosetLine(e, [...lines]);
        if (e.text!.contains(" ") && e.text!.split(" ")[0].length == 1 && isAlpha(e.text!.split(" ")[1])) {
          e.text = e.text!.substring(2).trim();
        }
        List<Line> missedLines = [];
        List<dynamic> r1 = doesNamesContainString(e.text, inputNames);
        List<dynamic> r2 = doesNamesContainString(next.text, inputNames);
        List<dynamic> r3 = doesNamesContain2String(e.text, next.text, inputNames);
        if (r1[0]) {
          for (int i = sortedLines.last.length - 1; i >= 0; i--) {
            Line l = sortedLines.last[i];
            if (e.cornerList![0].x < l.cornerList![3].x) {
              missedLines.add(l);
              sortedLines.last.removeAt(i);
            }
          }
          if (containsNumber(e.text ?? '')) {
            e.text = r1[1];
          } else {
            e.text = e.text!.substring(e.text!.toLowerCase().indexOf(r1[1].split(' ').first));
          }
          sortedLines.add([]);
        } else if (!r2[0] && r3[0]) {
          for (int i = sortedLines.last.length - 1; i >= 0; i--) {
            Line l = sortedLines.last[i];
            if (e.cornerList![0].x < l.cornerList![3].x) {
              missedLines.add(l);
              sortedLines.last.removeAt(i);
            }
          }
          sortedLines.add([]);
          String f0 = r3[1].split(' ').first;
          String f1 = r3[1].split(' ').last;
          if (r3[1].trim().split(' ').length > 2) {
            List<String> tempL = r3[1].trim().split(' ');
            tempL.removeLast();
            f0 = tempL.join(" ");
          }
          if (containsNumber(e.text ?? '')) {
            e.text = f0;
          } else {
            e.text = e.text!.substring(e.text!.toLowerCase().indexOf(r3[1].split(' ').first));
          }
          if (containsNumber(next.text ?? '')) {
            next.text = f1;
          } else {
            next.text = next.text!.substring(0, (next.text!.toLowerCase().indexOf(f1) + f1.length));
          }
        }
        sortedLines.last.add(e);
        for (Line l in missedLines) {
          sortedLines.last.add(l);
        }
      }
      if (sortedLines.length > 1) {
        sortedLines.remove(sortedLines.first);
      } else {
        return <Map<String, dynamic>>[];
      }
      int maxNameCount = 0;
      int maxListCount = 0;
      List<Line> maxList = [];
      // sorting method!
      sortedResult = '';
      sortedResultYAxis = '';
      sortedResultXAxis = '';
      sortedResultSlope = '';
      waitComplete = false;
      List<Map<String, dynamic>> passengers = <Map<String, dynamic>>[];
      for (int k = 0; k < sortedLines.length; k++) {
        List<Line> lineList = sortedLines[k];
        if (k == sortedLines.length - 1 && sortedLines.length > 1) {
          Line line = leastXFinder(lineList);
          lineList.removeWhere((e) => e.cornerList![0].x > line.cornerList![3].x);
        }
        sortedLines[k] = await exclusiveLineSort([...lineList]);
        lineList = sortedLines[k];

        ///these codes are to set maxNameCount and maxListCount
        //checks if the line is valid; it shouldn't share y!(be in one line)
        bool isValid = true;
        for (Line l in lineList) {
          if (lineList.first.cornerList![2].x < l.cornerList![0].x) {
            isValid = false;
          }
        }
        //sets maxNameCount and maxListCount.
        if (isValid) {
          bool b = true;
          int i1 = 0;
          int i2 = 0;
          for (int i = 0; i < lineList.length; i++) {
            Line l = lineList[i];
            if (b) b = !containsNumber(l.text ?? '');
            if (b) {
              i1++;
            } else {
              i2++;
            }
          }
          if (i1 > maxNameCount) maxNameCount = i1;
          if (i2 > maxListCount) {
            maxListCount = i2;
            maxList = [];
            for (int i = i1; i < lineList.length; i++) {
              Line l = lineList[i];
              maxList.add(Line(text: l.text, cornerList: l.cornerList));
            }
          }
        }
        if (k == (sortedLines.length - 1)) waitComplete = true;
      }
      await waitWhile(() => waitComplete);

      ///we will add temp Line to empty spaces of the table!
      waitComplete = false;
      for (int i = 0; i < sortedLines.length; i++) {
        List<Line> lineList = sortedLines[i];
        sortedLines[i] = await exclusiveLineFiller(lineList, maxList, maxNameCount);
        lineList = sortedLines[i];
        String fullName = lineList.sublist(0, maxNameCount).join(" ").trim();
        String seat = lineList.length > maxNameCount ? lineList[maxNameCount].text ?? '' : '';
        String seq = lineList.length - 1 > maxNameCount ? lineList[maxNameCount + 1].text ?? '' : '';
        String bag = '';
        OCRPassenger p = OCRPassenger(name: fullName, seat: seat, seq: seq, bag: bag);
        if (seat.isNotEmpty || seq.isNotEmpty) passengers.add(p.toJson());
        if (i == (sortedLines.length - 1)) waitComplete = true;
      }
      await waitWhile(() => waitComplete);
      // for (List<Line> lineList in sortedLines) {
      //   print(lineList.join(" "));
      // }
      return passengers;
    } catch (e) {
      print(e);
      return <Map<String, dynamic>>[];
    }
  }

  /// ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
  /// ***** ***** ***** ***** ***** [EXCLUSIVE_FUNCTIONS] ***** ***** ***** ***** ***** *****
  /// ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

  ///Algorithm set to handle a special sort
  Future<List<Line>> exclusiveLineSort(List<Line> lineList) async {
    List<Line> resultLines = [];
    // print("****************** ****************** ****************** ******************");
    // print(lineList.join(" "));
    for (int i = 0; i < lineList.length; i) {
      List<Line> subLines = [];
      Line line = leastXFinder(lineList);
      var maxX = line.cornerList![3].x;
      if (line.cornerList![0].x >= maxX) {
        subLines.add(lineList[i]);
        lineList.remove(lineList[i]);
      } else {
        for (int i = lineList.length - 1; i >= 0; i--) {
          if (lineList[i].cornerList![0].x < maxX) {
            subLines.add(lineList[i]);
            lineList.remove(lineList[i]);
          }
        }
      }
      // print(subLines.join(" "));
      // print("******------******");
      subLines.sort((a, b) => b.cornerList![0].y.compareTo(a.cornerList![0].y));
      sortedResult = sortedResult + subLines.join(" ") + " => ";
      sortedResultYAxis = sortedResultYAxis +
          subLines.map((e) => "(${e.cornerList![0].y.toStringAsFixed(2)})${e.text}").toList().join(" ") +
          " => ";
      sortedResultXAxis = sortedResultXAxis +
          subLines.map((e) => "(${e.cornerList![0].x.toStringAsFixed(2)})${e.text}").toList().join(" ") +
          " => ";
      sortedResultSlope = sortedResultSlope +
          subLines.map((e) => "(${slopeOfLine(e).toStringAsFixed(2)})${e.text}").toList().join(" ") +
          " => ";
      resultLines = resultLines + subLines;
    }
    sortedResult = sortedResult + "\n\n";
    sortedResultYAxis = sortedResultYAxis + "\n\n";
    sortedResultXAxis = sortedResultXAxis + "\n\n";
    sortedResultSlope = sortedResultSlope + "\n\n";
    return resultLines;
  }

  ///This algorithm takes a line list and fills it with temp Lines so all list lines follow one set of rules
  Future<List<Line>> exclusiveLineFiller(List<Line> lineList, List<Line> maxList, int maxNameCount) async {
    List<Line> result = [];
    //this part checks and adds names.
    for (int i = 0; i < lineList.length; i++) {
      Line l = lineList[i];
      if (l.cornerList![1].y > maxList.first.cornerList![0].y) {
        if (l.text!.length > 1) {
          result.add(l);
        }
      }
    }
    if (maxNameCount > result.length) {
      int c = maxNameCount - result.length;
      for (int i = 0; i < c; i++) {
        result.add(Line(text: ""));
      }
    }
    //this part checks and adds values.
    for (int i = 0; i < maxList.length; i++) {
      Line line = maxList[i];
      List<Line> lines = [...lineList];
      lines.removeWhere((element) =>
          (element.cornerList![0].y <= line.cornerList![1].y) ||
          (element.cornerList![1].y > line.cornerList![0].y) ||
          (result.contains(element)));
      result.add(lines.isEmpty ? Line(text: "", cornerList: line.cornerList) : lines.first);
    }
    return result;
  }

  /// ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
  /// ***** ***** ***** ***** ***** [SPECIAL_FORMATS] ***** ***** ***** ***** ***** *****
  /// ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

  ///format: ["123", "qwerty0", "qwe0rty"];
  ///checks if a string contains numbers.
  containsNumber(String s) {
    List<String> data = s.trim().split("");
    bool b = false;
    for (String e in data) {
      if (isNumeric(e)) {
        b = true;
      }
    }
    return b;
  }

  ///format: ["1B", "1A", "2A", "12A", "299C"];
  /// contains a number less than 300 and an alpha letter (a-zA-Z)
  isPassengerSeat(String s, String nextItem) {
    bool b = false;
    s = s.trim();
    //this layer handles little mistakes!
    if (nextItem != '' && isNumeric(nextItem)) {
      if (s.length == 3) {
        s = s[0] +
            s[1] +
            (s[2].replaceAll('8', 'b').replaceAll("0", "o").replaceAll('2', 'z').replaceAll("9", "g"));
      }
      if (s.length > 2 && isAlpha(s[s.length - 2])) {
        s = s.substring(0, s.length - 1);
      }
    }
    //this is the main check!
    if (s.length > 1 &&
        s.length < 5 &&
        isNumeric(s.substring(0, s.length - 1)) &&
        isAlpha(s.substring(s.length - 1, s.length))) b = true;
    return [b, s];
  }

  ///format: ["101", "102", "103"]
  ///it's a number up to 1000
  isPassengerSequence(String s) {
    s = s.trim();
    if (isNumeric(s) && s.length < 4) {
      int i = int.parse(s);
      if (i <= 1000) return true;
    }
    return false;
  }

  ///format: ["0/0", "1/12"]
  ///contains "/", and two numbers two side of it
  isPassengerBag(String s) {
    s = s.replaceAll('o', '0');
    if (s.contains('/') && isNumeric(s.split('/')[0]) && isNumeric(s.split('/')[0])) return true;
    return false;
  }

  ///format: ["2100635585", "1361535733", "00A7925289", "00A4781591"];
  ///contains 10(sometimes 9) characters, mostly numbers;
  isPassengerID(String s) {
    int a = 0, n = 0;
    s.split('').forEach((e) {
      if (isNumeric(e)) {
        n++;
      } else if (isAlpha(e)) {
        a++;
      }
    });
    return (s.length > 6 && a < 2 && n >= 6);
  }
}
