import 'dart:convert';
import 'dart:io';

import 'package:bouncer/partyStructure.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class UserScan extends StatefulWidget {
  UserScan(this.ref);

  DatabaseReference ref;

  @override
  _UserScanState createState() => _UserScanState();
}

class _UserScanState extends State<UserScan> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR2');

  Barcode? result;
  Color _mesageColor=Colors.redAccent;
  String _message="Scan Code";
  QRViewController? controller;
  late Party party;

  bool _scanning = false;

  Future<bool> isValid(String partyName, String partyCode) async {
    DataSnapshot snapshot = await widget.ref.child(partyName).once();

    if (!snapshot.exists) {
      print("name does not exist");
      return false;
    }
    String p = json.decode(snapshot.value)["partyCode"].toString();

    print(partyCode);
    print(p);

    if (p != partyCode) {
      print("code does not exist");

      return false;
    }

    return true;
  }

  Future<void> updateParty(String PartyName) async {
    await widget.ref.child(PartyName).once().then((DataSnapshot data) {
      //print(data.value);
      if (data.value != null) {
        party.fromjson(json.decode(data.value));
      }else{
        print("party instance created in firebase");
        String str = json.encode(party.toJson());
        widget.ref.child(PartyName).set(str);
      }
    });
    setState(() {

    });
  }

  Future<void> uploadParty(String PartyName) async{
    String str = json.encode(party.toJson());
    widget.ref.child(PartyName).set(str);
  }


  Future<void> scandata(Barcode result) async {
    _scanning = true;

    print(result.code);
    bool temp=false;
    if(result.code.contains(",")){
      temp = await isValid(result.code.split(",")[0], result.code.split(",")[1]);
    }

    if (temp) {

      setState(() {
        _mesageColor=Colors.green;
        _message="Accepted";
      });

      await updateParty(result.code.split(",")[0]);

      String id=party.generateId();

      party.guestList.add(id);

      await uploadParty(result.code.split(",")[0]);


      Navigator.pop(context,id);




    }else{

      setState(() {
        _mesageColor=Colors.orangeAccent;
        _message="Invalid Code";
      });


    }
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _mesageColor=Colors.redAccent;
      _message="Scan Code";
    });
    _scanning = false;
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      result = scanData;

      print("scanned");
      if (!_scanning) {
        scandata(result!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Container(
                width: MediaQuery.of(context).size.width,
                color: _mesageColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context, "0");
                        },
                        icon: Icon(
                          Icons.arrow_back_outlined,
                          size: 30,
                        )),
                    Text(
                      _message,
                      style: TextStyle(fontSize: 30),
                    ),
                    Icon(
                      Icons.code,
                      color: Colors.transparent,
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  void initState() {
    party = Party(partyCode: "", partyName: "", guestsInside: [], guestList: []);
    super.initState();
  }
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

}
