import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:bouncer/login.dart';
import 'package:bouncer/partyStructure.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share/share.dart';
import 'package:share_files_and_screenshot_widgets_plus/share_files_and_screenshot_widgets_plus.dart';

import 'User.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.dark(),
      ),
      home: LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.partyCode, required this.ref, required this.partyName}) : super(key: key);
  DatabaseReference ref;
  final String partyCode;
  final String partyName;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool _scanning = false;
  String _homeID = "";
  late Party party;

  ScreenshotController screenshotController = ScreenshotController();

  String _message = "Scan Code";
  Color _messageColor = Colors.redAccent;



  Future<void> updateParty() async {
    await widget.ref.child(widget.partyName).once().then((DataSnapshot data) {
      //print(data.value);
      if (data.value != null) {
        party.fromjson(json.decode(data.value));
      }else{
        print("party instance created in firebase");
        String str = json.encode(party.toJson());
        widget.ref.child(widget.partyName).set(str);
      }
    });
    setState(() {

    });
  }

  Future<void> uploadParty() async{
    String str = json.encode(party.toJson());
    widget.ref.child(widget.partyName).set(str);
  }

  shareCode() async {


    String id=party.generateId();
    party.guestList.add(id);
    await uploadParty();

    screenshotController
        .captureFromWidget(
      QrImage(
        data: id,
        version: QrVersions.auto,
      ),
    )
        .then((image) async {
      final directory = (await getApplicationDocumentsDirectory()).path;
      File imgFile = new File('$directory/photo.png');
      await imgFile.writeAsBytes(image);
      await Share.shareFiles([imgFile.path], text: "Show this code to get in to the party");
    }).catchError((onError) {
      print(onError);
    });

    setState(() {

    });
  }

  Future<void> scandata(Barcode result) async {
    _scanning = true;
    await updateParty();

    print(result.code);
    print(party.guestList);


    if (party.isInside(result.code)) {

      _messageColor = Colors.orangeAccent;
      _message = "Reused Code";
    }

    if (party.onguestList(result.code) && !party.isInside(result.code)) {
      party.guestsInside.add(result.code);
      setState(() {
        _messageColor = Colors.green;
        _message = "Approved";
      });
    }

    if (!party.onguestList(result.code)) {
      setState(() {
        _messageColor = Colors.orangeAccent;
        _message = "Rejected";
      });
    }

    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _message = "Scan Code";
      _messageColor = Colors.redAccent;
    });
    await uploadParty();
    _scanning = false;

  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      if (!_scanning) {
        scandata(result!);
      }
    });
  }

  Scaffold page2() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Container(
                width: MediaQuery.of(context).size.width,
                color: _messageColor,
                child: Center(
                    child: Text(
                  _message,
                  style: TextStyle(fontSize: 30),
                ))),
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

  Scaffold page1(DatabaseReference ref) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          widget.partyName,
          style: TextStyle(fontSize: 25),
        ),
        leadingWidth: 80,
        leading: IconButton(
          icon: Icon(
            Icons.home,
            size: 30,
          ),
          onPressed: () {
            Navigator.push(context, PageTransition(type: PageTransitionType.topToBottom, duration: Duration(milliseconds: 500), child: LoginPage()));
       },
        ),
        actions: [
          TextButton(
              onPressed: () {
                shareCode();
              },
              child: Text(
                "Invite",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ))
        ],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 90),
              child: GestureDetector(
                onDoubleTap: () {
                  String str = json.encode(
                    Party(partyName: "test", partyCode: "test", guestList: [], guestsInside: []).toJson(),
                  );
                  print(str);
                 // ref.child(widget.partyCode).set(Party(partyName: "TESTNAME", partyCode: "TESTCODE", guestList: [], guestsInside: []).toJson().toString());
                },
                onTap: () {
                  ref.child(widget.partyName).once().then((DataSnapshot data) {
                    print(data.value);
                  });

                },
                child: QrImage(
                  size: 200,
                  data: "${party.partyName},${party.partyCode}",
                  foregroundColor: Colors.white,
                  version: QrVersions.auto,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 90),
              child: CupertinoButton(
                  color: Colors.transparent,
                  child: Text(
                    "Send Invite",
                    style: TextStyle(color: Colors.transparent, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    shareCode();
                  }),
            ),
            Expanded(
              child: Container(
                decoration: new BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: new BorderRadius.only(
                      topLeft: const Radius.circular(40.0),
                      topRight: const Radius.circular(40.0),
                    )),
                width: MediaQuery.of(context).size.width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
                            child: Text(
                              "Party Info",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Invitations Sent",
                            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            party.guestList.length.toString(),
                            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 50, top: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "People Inside",
                              style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              party.guestsInside.length.toString(),
                              style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: PageView(
        controller: PageController(keepPage: true),
        scrollDirection: Axis.vertical,
        children: [page1(widget.ref), page2()],
      ),
    );
  }

  @override
  void initState() {
    party = Party(partyCode: widget.partyCode, partyName: widget.partyName, guestsInside: [], guestList: []);
    updateParty();
    super.initState();
  }
}
