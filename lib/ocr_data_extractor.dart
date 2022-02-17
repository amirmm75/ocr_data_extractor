import 'dart:async';
import 'dart:convert';
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
  String sortedResultVertical = '';
  String spaceBetweenWords = '';
  String spaceBetweenWordsVertical = '';
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
        removeFromTopWords: [" seat ", " type ", " name "],
        removeFromTopWords2: [" date:", " gate:"]);
    List<Line>? lines2 = [...lines!];
    String horizontalSort = await initSort(lines,
        spaceBetweenWordsCount: 1, strictness: strictness);
    String verticalSort =
        await initSort(lines2, spaceBetweenWordsCount: 1, isHorizontal: false);
    List<Map<String, dynamic>> finalResult =
        await findPassengers(horizontalSort, verticalSort, inputNames);
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

  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
  ///***** ***** ***** ***** ***** [INITIAL_AND_USEFUL_FUNCTIONS] ***** ***** ***** *****
  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

  ///extracts each every word
  ///has a feature that takes a list of String (removeFromTopWords) and finds out which one of them is the
  /// highest and removes the upper words! removeFromTopWords2 removes the words themselves too.
  ///example of a valid list: [" name ", " seat ", " type "]. don't forget the space!
  Future<List<Line>?> initialize(Map<String, dynamic> output,
      {List<String> removeFromTopWords = const [],
      List<String> removeFromTopWords2 = const []}) async {
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
        Line maxXLine = obj.lines!.reduce((value, element) =>
            value.cornerList![2].x > element.cornerList![2].x
                ? value
                : element);
        var maxX = maxXLine.cornerList![2].x;
        for (var element in obj.lines!) {
          Line line = Line(
            text: element.text,
            cornerList: [
              CornerPoint(
                  x: element.cornerList![0].y,
                  y: maxX - element.cornerList![0].x),
              CornerPoint(
                  x: element.cornerList![1].y,
                  y: maxX - element.cornerList![1].x),
              CornerPoint(
                  x: element.cornerList![2].y,
                  y: maxX - element.cornerList![2].x),
              CornerPoint(
                  x: element.cornerList![3].y,
                  y: maxX - element.cornerList![3].x)
            ],
          );
          lines.add(line);
        }
      } else {
        lines = obj.lines;
      }
      if (removeFromTopWords.isNotEmpty || removeFromTopWords2.isNotEmpty) {
        double minX = 0;
        double maxX = 0;
        for (Line l in lines!) {
          for (String s in removeFromTopWords) {
            if (" ${l.text!} ".toLowerCase().contains(s.toLowerCase())) {
              if (l.cornerList![0].x < minX || minX == 0) {
                minX = l.cornerList![0].x + 0.1;
              }
            }
          }
          for (String s in removeFromTopWords2) {
            if (" ${l.text!} ".toLowerCase().contains(s.toLowerCase())) {
              if (l.cornerList![2].x > maxX) maxX = l.cornerList![2].x + 0.1;
            }
          }
        }
        if (maxX > minX) minX = maxX;
        if (minX != 0) {
          for (int i = lines.length - 1; i >= 0; i--) {
            Line l = lines[i];
            if (l.cornerList![2].x <= minX) {
              lines.removeWhere((e) => e == l);
            }
          }
        }
      }
      return lines;
    }
  }

  ///takes a String (line) which is a line and contains a list of Strings joined with space and each one of
  ///them much validate. if most of them returned true then the function must return true
  bool validateFeatureInLine(
      String line, double percent, bool Function(String) validate) {
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
            l2.cornerList![2].x -
                10 || //strictness == Strictness.medium, more sensitive
        l1.cornerList![2].x < l2.cornerList![0].x + 10) {
      //this is the first and the most important layer of filter
      isInSameLines = false;
    }
    if (l1.cornerList![0].y < l2.cornerList![2].y &&
        l1.cornerList![2].y > l2.cornerList![0].y) {
      //if they have any horizontal sharing in space they must not be in the same line
      isInSameLines = false;
    }
    if ((l1.cornerList![2].x - l1.cornerList![0].x) >
            3 * (l2.cornerList![2].x - l2.cornerList![0].x) ||
        (l2.cornerList![2].x - l2.cornerList![0].x) >
            3 * (l1.cornerList![2].x - l1.cornerList![0].x)) {
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
    } else if (l1.cornerList![0].y <
            l2.cornerList![2]
                .y || //strictness == Strictness.medium, more sensitive
        l1.cornerList![2].y > l2.cornerList![0].y) {
      //this is the first and the most important layer of filter
      isInSameLines = false;
    }
    if (l1.cornerList![0].x < l2.cornerList![2].x &&
        l1.cornerList![2].x > l2.cornerList![0].x) {
      //if they have any vertical sharing in space they must not be in the same line
      isInSameLines = false;
    }
    if ((l1.cornerList![2].x - l1.cornerList![0].x) >
            3 * (l2.cornerList![2].x - l2.cornerList![0].x) ||
        (l2.cornerList![2].x - l2.cornerList![0].x) >
            3 * (l1.cornerList![2].x - l1.cornerList![0].x)) {
      //sometimes a really big font is near a small font which doesn't mean they meant to be in the same line
      isInSameLines = false;
    }
    return isInSameLines;
  }

  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
  ///***** ***** ***** ***** ***** [SORTING_ALGORITHM] ***** ***** ***** ***** *****
  ///***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

  ///Sorts all lines
  ///probably the most accurate algorithm for sorting lines
  ///the length of space between words of a line is 4 and it's changeable!
  initSort(List<Line>? allLines,
      {int spaceBetweenWordsCount = 4,
      bool isHorizontal = true,
      int strictness = 1}) async {
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
    await waitWhile(
        () => isHorizontal ? isSortComplete : isSortCompleteVertical);
    return isHorizontal
        ? sortedResult
        : sortedResultVertical; //the data is ready to use!
  }

  Future waitWhile(bool Function() test,
      [Duration pollInterval = Duration.zero]) {
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

  sortLines(List<Line>? lines, String spaceBetweenWords, bool isHorizontal,
      int strictness) {
    //add entireLines
    if (lines == null || lines.isEmpty) {
      isHorizontal ? isSortComplete = true : isSortCompleteVertical = true;
    } else {
      List<Line> sameLines = [];
      Line firstLine = isHorizontal ? leastXFinder(lines) : maxYFinder(lines);
      sameLines.add(firstLine);
      lines.removeWhere((element) => element == firstLine);
      findSameLines(
          lines, sameLines, spaceBetweenWords, isHorizontal, strictness);
    }
  }

  findSameLines(List<Line> allLines, List<Line> sameLines,
      String spaceBetweenWords, bool isHorizontal, int strictness) {
    Line newLine = Line();
    bool isInSameLines = true;
    // is newLine in same lines?
    if (allLines.isEmpty) {
      isInSameLines = false;
    } else {
      newLine = isHorizontal ? leastXFinder(allLines) : maxYFinder(allLines);
      if (strictness < 2) {
        for (var element in sameLines) {
          if ((isHorizontal
              ? !isInTheSameLine(newLine, element,
                  strictness == 0 ? Strictness.medium : Strictness.hard)
              : !isInTheSameColumn(newLine, element, Strictness.medium))) {
            isInSameLines = false;
          }
        }
      } else {
        Line element = sameLines.last;
        if ((isHorizontal
            ? !isInTheSameLine(newLine, element,
                strictness == 0 ? Strictness.medium : Strictness.hard)
            : !isInTheSameColumn(newLine, element, Strictness.medium))) {
          isInSameLines = false;
        }
      }
    }
    // yes? find same lines again, no? sort lines again
    if (isInSameLines) {
      sameLines.add(newLine);
      allLines.removeWhere((element) => element == newLine);
      findSameLines(
          allLines, sameLines, spaceBetweenWords, isHorizontal, strictness);
    } else {
      List<Line> sortedLines = [];
      String result = isHorizontal ? sortedResult : sortedResultVertical;
      int lastI = sameLines.length;
      for (int i = 0; i < lastI; i++) {
        Line max =
            isHorizontal ? maxYFinder(sameLines) : leastXFinder(sameLines);
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

  leastXFinder(List<Line> lines) {
    Line firstLine = lines.reduce((value, element) =>
        value.cornerList![0].x < element.cornerList![0].x ? value : element);
    return firstLine;
  }

  maxXFinder(List<Line> lines) {
    Line firstLine = lines.reduce((value, element) =>
        value.cornerList![0].x > element.cornerList![0].x ? value : element);
    return firstLine;
  }

  leastYFinder(List<Line> lines) {
    Line firstLine = lines.reduce((value, element) =>
        value.cornerList![0].y < element.cornerList![0].y ? value : element);
    return firstLine;
  }

  maxYFinder(List<Line> lines) {
    Line firstLine = lines.reduce((value, element) =>
        value.cornerList![0].y > element.cornerList![0].y ? value : element);
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
        if (s.length > 5 &&
            !(l.text?.contains("/") ?? false) &&
            !(l.text?.contains(".") ?? false)) {
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
  Future<List<Map<String, dynamic>>> findPassengers(String horizontalSort,
      String verticalSort, List<String> inputNames) async {
    // print(horizontalSort);
    // print("**************************** ************************************** ********************");
    // print(verticalSort);
    // print("**************************** ************************************** ********************");
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
    //this needs work
    //without inputNames no item will add
    if (inputNames.isEmpty) return [];
    //searching among input names
    for (String n in inputNames) {
      BestMatch bestMatch = n.toLowerCase().bestMatch(searchingNames);
      if ((bestMatch.bestMatch.rating ?? 0) > 0.85) {
        String rawName = bestMatch.bestMatch.target ?? '';
        int index = searchingNames.indexOf(rawName);
        String s = searchingItems[index].replaceFirst(
            rawName.replaceFirst(" ", spaceBetweenWords),
            n.replaceFirst(" ", spaceBetweenWords));
        results.add(s);
      }
    }
    //we don't need it yet.
    // //values extracted in results... now we use vertical sort to extract the values of it.
    // List<String> verticalLines = verticalSort.toLowerCase().split("\n");
    // int seatIndex;
    // int seqIndex;
    // int idIndex;
    // int typeIndex;
    // int ciIndex;
    // int statusIndex;
    // int agentIndex;
    // for (int i = 1; i < verticalLines.length; i++) {
    //   print(verticalLines[i]);
    //   //this returns if values are "Seat" or not
    //   if (validateFeatureInLine(verticalLines[i].trim(), 33, (String s) => isPassengerSeat(s))) {
    //     seatIndex = i;
    //     break;
    //   }
    // }
    List<Map<String, dynamic>> passengers = [];
    for (String n in results) {
      // print(n);
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
          seq = items
              .sublist(i + 1)
              .firstWhere((e) => isPassengerSequence(e), orElse: () => '');
          if (i < items.length - 2 &&
              seq.length == 1 &&
              seq == items[i + 1] &&
              isPassengerSequence(items[i + 2])) seq = items[i + 2];
          break;
        } else if (isAlpha(items[i]) && i < 3) {
          fullName = fullName + items[i] + ' ';
        }
      }
      bag = items
          .firstWhere((s) => isPassengerBag(s), orElse: () => '')
          .replaceAll('o', '0');
      fullName = fullName.trim();
      seq = seq.trim();
      OCRPassenger p =
          OCRPassenger(name: fullName, seat: seat, seq: seq, bag: bag);
      if (seat.isNotEmpty) passengers.add(p.toJson());
    }
    // print("**************************** **************************************");
    // print(passengers);
    //we return processed output here;
    return passengers;
  }

  /// ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****
  /// ***** ***** ***** ***** ***** [SPECIAL_FORMATS] ***** ***** ***** ***** ***** *****
  /// ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** ***** *****

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
            (s[2]
                .replaceAll('8', 'b')
                .replaceAll("0", "o")
                .replaceAll('2', 'z')
                .replaceAll("9", "g"));
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
    if (s.contains('/') &&
        isNumeric(s.split('/')[0]) &&
        isNumeric(s.split('/')[0])) return true;
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
