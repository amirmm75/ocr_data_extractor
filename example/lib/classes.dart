class BackUpOCRPassenger {
  String fName = '';
  String lName = '';
  String name = '';
  String seat = '';
  int seq = 0;
  String weight = '';
  String count = '';
  String bag = '';

  BackUpOCRPassenger(
      {required this.name,
      required this.fName,
      required this.lName,
      required this.seat,
      required this.seq,
      required this.weight,
      required this.count,
      required this.bag});

  BackUpOCRPassenger.fromJson(Map<String, dynamic> json) {
    name = json["FullName"];
    fName = json["FirstName"];
    lName = json["LastName"];
    seat = json["Seat"];
    seq = int.tryParse(json["Seq"].toString()) ?? 0;
    weight = json["Weight"];
    count = json["Count"];
    bag = "${json["Count"]}/${json["Weight"]}";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['FirstName'] = fName;
    data['LastName'] = lName;
    data['FullName'] = name;
    data['Seat'] = seat;
    data['Seq'] = seq;
    data['Weight'] = weight;
    data['Count'] = count;
    return data;
  }

  @override
  String toString() {
    return "$name--Seat:$seat--Seq:${seq.toString()}";
  }
}
