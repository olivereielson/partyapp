

class Party{

  Party({ required this.partyName, required this.partyCode});


  List<int>_guestList=[];
  List<int>_guestsInside=[];

  String partyName;
  String partyCode;




  Map<String, dynamic> toJson() =>
      {
        '_guestList': _guestList,
        '_guestsInside': _guestsInside,
        'partyName': partyName,
        'partyCode': partyCode,
      };


}