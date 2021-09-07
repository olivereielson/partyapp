import 'dart:convert';

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

  Future<void> scandata(Barcode result) async {
    _scanning = true;

    print(result.code);
    bool temp=false;
    if(result.code.contains(",")){
      temp = await isValid(result.code.split(",")[0], result.code.split(",")[1]);
    }

    if (temp) {


    }else{

      _mesageColor=Colors.orangeAccent;
      _message="Invalid Code";

    }
    await Future.delayed(Duration(seconds: 1));

    _scanning = false;
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      result = scanData;

      if (!_scanning) {
        scandata(result!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Container(
              width: MediaQuery.of(context).size.width,
              color: Colors.redAccent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context, 0);
                      },
                      icon: Icon(
                        Icons.arrow_back_outlined,
                        size: 30,
                      )),
                  Text(
                    "Scan Code",
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
    );
  }
}
