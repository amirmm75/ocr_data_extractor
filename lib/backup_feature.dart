import 'package:artemis_camera_kit/artemis_camera_kit_platform_interface.dart';
import 'package:string_validator/string_validator.dart';
import 'classes.dart';

///a simple function that finds out if a text of [line] exists in a list of string.
bool isStringInList(OcrLine line, List<String> inputNames) {
  String s = line.text.trim();
  return inputNames.any((name) => name.split(" ").any((item) => s.contains(item)));
}

///This function compares two OcrLine with on another.
///the code calculates if [l1] has more horizontal sharing with [line] or not.
///[l1] & [l2] must be in a same row and both of them must have a horizontal sharing with [line].
///[l1] is considered to be left of the [l2].
bool overlapComparison(OcrLine line, OcrLine l1, OcrLine l2) {
  double d1 = line.cornerPoints[0].y - l1.cornerPoints[1].y;
  double d2 = l2.cornerPoints[0].y - line.cornerPoints[1].y;
  return d1 > d2;
}

///This algorithm takes [sortedLines] and fills it with temp Lines using [maxList] to set a matrix
List<List<OcrLine>> exclusiveMatrixFiller(List<List<OcrLine>> sortedLines, List<OcrLine> maxList) {
  List<List<OcrLine>> tempSortedLines = [...sortedLines];
  for (int i = 0; i < tempSortedLines.length; i++) {
    List<OcrLine> operatingLines = [...tempSortedLines[i]];
    List<OcrLine> filledLines = [];
    for (int j = 0; j < maxList.length; j++) {
      OcrLine maxLine = maxList[j];
      OcrLine selectedLine = operatingLines.firstWhere(
          (ol) =>
              ol.cornerPoints[0].y > maxLine.cornerPoints[2].y &&
              ol.cornerPoints[2].y < maxLine.cornerPoints[0].y,
          orElse: () => OcrLine(text: "", cornerPoints: maxLine.cornerPoints));
      filledLines.add(selectedLine);
      if (selectedLine.text.isNotEmpty) operatingLines.remove(selectedLine);
    }
    if (operatingLines.isNotEmpty) {
      // print("maxList problem solving!");
      //'qwertyUi' in maxList
      //'as' 'fgh' in operatingList
      //'fgh' might be missed!!! maxList must change and divide and redo of the process is required
      //tip: use sortedLines[i] for finding the index!
      for (int j = operatingLines.length - 1; j >= 0; j--) {
        int index = sortedLines[i].indexOf(operatingLines[j]); //this is the index of 'fgh'
        OcrLine prevLine = sortedLines[i][index - 1]; //we found 'as'! time to find 'qwertyUi'!
        int targetIndex = filledLines.indexOf(prevLine);
        // if 'fgh' has more overlap than 'as'? then use 'fgh' instead of 'as'!
        if (!overlapComparison(maxList[targetIndex], prevLine, operatingLines[j])) {
          //usually this happens because of the first icon or solo character before the name!
          filledLines[targetIndex] = operatingLines[j];
        }
      }
      // end of optional problem solve!
    }
    tempSortedLines[i] = filledLines;
  }
  return tempSortedLines;
}

///function used to extract flight passenger data using input names for a dcs passenger list.
fastExtractPassengersData(List<OcrLine> lines, List<String> inputNames) async {
  lines.sort((a, b) => a.cornerPoints[0].x.compareTo(b.cornerPoints[0].x));
  List<List<OcrLine>> sortedLines = [[]];
  List<OcrLine> maxList = [];

  ///we should extract the matrix of data first!
  //we start from the last!
  //Search till you find out a name.
  //start checking from the last and remove all that is beneath the found name.
  //continue checking and add all the words which are in the similar line of the name and remove them from the list and add store them.
  List<OcrLine> tempExtractMatrix = [];
  for (int i = lines.length - 1; i >= 0; i--) {
    OcrLine line = lines[i];
    if (isStringInList(line, inputNames)) {
      tempExtractMatrix = [];
      double lineTop = line.cornerPoints[0].x;
      double lineBot = line.cornerPoints[3].x;
      for (int j = lines.length - 1; (j >= 0 && lines[j].cornerPoints[3].x > lineTop); j--) {
        if (lines[j].cornerPoints[0].x < lineBot) {
          tempExtractMatrix.add(lines[j]);
          if (!maxList.any((e) =>
              e.cornerPoints[0].y > lines[j].cornerPoints[2].y &&
              e.cornerPoints[2].y < lines[j].cornerPoints[0].y)) {
            maxList.add(OcrLine(text: lines[j].text, cornerPoints: lines[j].cornerPoints));
          }
        }
        lines.removeAt(j);
        i = j - 1;
      }
      tempExtractMatrix.sort((a, b) => b.cornerPoints[0].y.compareTo(a.cornerPoints[0].y));
      sortedLines = [tempExtractMatrix] + sortedLines;
    }
  }
  maxList.sort((a, b) => b.cornerPoints[0].y.compareTo(a.cornerPoints[0].y));
  sortedLines.removeLast();
  if (sortedLines.isEmpty) return <Map<String, dynamic>>[];

  ///let's fill the empty matrix elements!
  sortedLines = exclusiveMatrixFiller(sortedLines, maxList);
  // for (var lines in sortedLines) {
  //   print(lines.map((e) => e.text).toList().join("' '"));
  //   print("");
  // }

  ///find the type of every column
  int seatIndex = -1;
  int seqIndex = -1;
  int seatCount = 0;
  int seqCount = 0;
  int nameStartIndex = -1;
  int prevName0 = 0;
  int nameTotal0 = 0;
  List<int> nameCounts = [];
  bool isSeqOrganized = true;
  for (int i = 0; i < maxList.length; i++) {
    int name0 = 0;
    int seat0 = 0;
    int seq0 = 0;
    int bag0 = 0;
    for (List<OcrLine> lineList in sortedLines) {
      OcrLine l = lineList[i];
      if (isPassengerName(l.text)) name0++;
      if (isPassengerSeat(l.text)) seat0++;
      if (isPassengerSequence(l.text)) seq0++;
      if (isPassengerBag(l.text)) bag0++;
    }
    nameCounts.add(name0);
    if (name0 + prevName0 > nameTotal0) {
      nameTotal0 = name0 + prevName0;
      prevName0 = name0;
      nameStartIndex = i - 1;
    } else {
      nameTotal0 = name0 + prevName0;
      prevName0 = name0;
    }
    if (seat0 > bag0 && seat0 > seq0 && seat0 > seatCount) {
      seatIndex = i;
      seatCount = seat0;
    }
    if (seq0 > seat0 && seq0 > bag0 && seq0 > seqCount) {
      seqIndex = i;
      seqCount = seq0;
      isSeqOrganized = true;
      //use this later!
      isSeqOrganized = isSeqOrganized;
      for (int j = 1; j < sortedLines.length; j++) {
        String bef = sortedLines[j - 1][i].text;
        String aft = sortedLines[j][i].text;
        int a0 = int.tryParse(bef) ?? -1;
        int a1 = int.tryParse(aft) ?? -1;
        if (a0 >= 0 && a1 >= 0 && (a0 - a1) != 1 && (a1 - a0) != 1) {
          isSeqOrganized = false;
        }
      }
    }
    // if (bag0 > seat0 && bag0 > seq0 && bag0 > bagCount) {
    //   bagIndex = i;
    //   bagCount = seq0;
    // }
  }

  ///return passengers with their results
  List<Map<String, dynamic>> passengers = <Map<String, dynamic>>[];
  if (nameStartIndex < 0) return <Map<String, dynamic>>[];
  for (List<OcrLine> lines in sortedLines) {
    String fullName = lines[nameStartIndex].text + " " + lines[nameStartIndex + 1].text;
    if (nameStartIndex + 2 < lines.length &&
        nameStartIndex + 2 != seatIndex &&
        nameStartIndex + 2 != seqIndex &&
        nameCounts[nameStartIndex + 2] > 0 &&
        lines[nameStartIndex + 2].text.isNotEmpty) {
      fullName = fullName + " " + lines[nameStartIndex + 2].text;
    }
    String seat = '';
    String seq = '';
    if (seatIndex >= 0) {
      seat = lines[seatIndex].text.trim();
      //seat correction
      if (!isPassengerSeat(seat)) {
        seat = seat.toLowerCase().replaceAll(" ", "");
        if (seat.length > 2 && isAlpha(seat.substring(seat.length - 2, seat.length))) {
          seat = seat.substring(0, seat.length - 1);
        }
        if (seat.length > 3) {
          seat = seat.substring(seat.length - 3);
        }
        String lastS = seat.substring(seat.length - 1);
        if (!isAlpha(lastS)) {
          lastS = lastS
              .replaceAll('8', 'b')
              .replaceAll("0", "o")
              .replaceAll('2', 'z')
              .replaceAll("9", "g")
              .replaceAll(")", "j")
              .replaceAll("]", "j");
          seat = seat.substring(0, seat.length - 1) + lastS;
        }
      }
    }
    if (seqIndex >= 0) {
      seq = lines[seqIndex].text.trim();
      //sequence correction
      if (!isPassengerSequence(seq)) {
        seq = seq
            .toUpperCase()
            .replaceAll(" ", "")
            .replaceAll("O", "0")
            .replaceAll("L", "1")
            .replaceAll("I", "1")
            .replaceAll("T", "1")
            .replaceAll('Z', '2')
            .replaceAll("G", "9");
      }
    }
    OCRPassenger p =
        OCRPassenger(id: sortedLines.indexOf(lines).toString(), name: fullName, seat: seat, seq: seq);
    if (seat.isNotEmpty || seq.isNotEmpty) passengers.add(p.toJson());
  }
  return passengers;
}

///format: "Amir" XD
/// contains alpha letters (a-zA-Z)
/// doesn't really have to be a name! we just use it generally!
isPassengerName(String s) {
  bool b = false;
  if (s.length > 3 && isAlpha(s)) {
    b = true;
  }
  return b;
}

///format: ["1B", "1A", "2A", "12A", "299C"];
/// contains a number less than 300 and an alpha letter (a-zA-Z)
isPassengerSeat(String s) {
  bool b = false;
  s = s.trim();
  if (s.length > 1 &&
      s.length < 5 &&
      isNumeric(s.substring(0, s.length - 1)) &&
      isAlpha(s.substring(s.length - 1, s.length))) b = true;
  return b;
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
