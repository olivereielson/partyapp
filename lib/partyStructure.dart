import 'dart:math';

class Party {
  Party({required this.partyName, required this.partyCode, required this.guestsInside, required this.guestList});

  List<String> guestList;
  List<String> guestsInside;

  String partyName;
  String partyCode;

  Party.fromJson(Map<String, dynamic> json)
      : guestList = json['guestList'],
        guestsInside = json['guestsInside'],
        partyName = json['partyName'],
        partyCode = json['partyCode'];

  bool onguestList(String id) {
    if (guestList.contains(id)) {
      return true;
    }

    return false;
  }

  bool isInside(String id) {
    if (guestsInside.contains(id)) {
      return true;
    }

    return false;
  }

  void fromjson(Map<String, dynamic> json) {
    guestList = json['guestList'].cast<String>();
    guestsInside = json['guestsInside'].cast<String>();
    partyName = json['partyName'];
    partyCode = json['partyCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['guestList'] = this.guestList.cast<String>();
    data['guestsInside'] = this.guestsInside.cast<String>();
    data['partyName'] = this.partyName;
    data['partyCode'] = this.partyCode;

    return data;
  }

  String generateId() {
    var rng = new Random();


    String date =DateTime.now().microsecondsSinceEpoch.toString();

    String inviteID = partyName.toUpperCase()+"-"+date.substring(date.length-5)+ "-"+rng.nextInt(100000).toString();

    print(inviteID);

    return inviteID;
  }
}
