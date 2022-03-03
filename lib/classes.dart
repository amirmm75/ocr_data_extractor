class Object {
  List<Line>? lines;

  Object({this.lines});

  Object.fromJson(Map<String, dynamic> json) {
    if (json['items'] != null) {
      lines = [];
      json['items'].forEach((v) {
        lines!.add(Line.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (lines != null) {
      data['items'] = lines!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

/// x and y are different from mathematical coordinates. they are the exact opposite! Check the example below
///CornerPoint[0]{x=0, y=1}            CornerPoint[1]{x=0, y=0}
///CornerPoint[3]{x=1, y=1}            CornerPoint[2]{x=1, y=0}
class Line {
  String? text;
  List<CornerPoint>? cornerList;

  Line({this.text, this.cornerList});

  Line.fromJson(Map<String, dynamic> json) {
    text = json['text'];
    if (json['cornerPoints'] != null) {
      cornerList = [];
      json['cornerPoints'].forEach((v) {
        cornerList!.add(CornerPoint.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['text'] = text;
    if (cornerList != null) {
      data['cornerPoints'] = cornerList!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  @override
  String toString() {
    // return "$text--0:[x: ${cornerList![0].x.toString()}, y:${cornerList![0].y.toString()}]--2:[x: ${cornerList![2].x.toString()}, y:${cornerList![2].y.toString()}]";
    return "(${cornerList![0].y.toStringAsFixed(2)})$text";
  }
}

class CornerPoint {
  var x;
  var y;

  CornerPoint({this.x, this.y});

  CornerPoint.fromJson(Map<String, dynamic> json) {
    x = json['x'];
    y = json['y'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['x'] = x;
    data['y'] = y;
    return data;
  }
}

enum Strictness { hard, medium }

class PassengerList {
  PassengerList({required this.passengerList});

  List<OCRPassenger> passengerList;

  Map<String, dynamic> toJson() => {
        "PassengerList": List<dynamic>.from(passengerList.map((x) => x.toJson())),
      };
}

class OCRPassenger {
  String name;
  String seat;
  String seq;
  String bag;

  // String id;
  // String type;
  // String ci;
  // String status;
  // String agent;

  OCRPassenger({required this.name, this.seat = '', this.seq = '', this.bag = ''});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['FirstName'] = name.split(" ").first.toTitleCase();
    data['LastName'] = name.split(" ").last.toTitleCase();
    data['FullName'] = name.toTitleCase();
    data['Seat'] = seat.toUpperCase();
    data['Seq'] = seq;
    data['Weight'] = bag.isNotEmpty ? bag.split("/")[1] : '';
    data['Count'] = bag.isNotEmpty ? bag.split("/")[0] : '';
    return data;
  }
}

extension StringCasingExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';

  String toTitleCase() =>
      replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');
}
