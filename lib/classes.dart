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

class Line {
  // x and y are the exact opposite of mathematical coordinate
  //CornerPoint[0]{x=0, y=0}            CornerPoint[1]{x=0, y=1}
  //CornerPoint[3]{x=1, y=0}            CornerPoint[2]{x=1, y=1}
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
