import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bouncer/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.red, colorScheme: ColorScheme.dark()),
      home: LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.partyCode, required this.ref}) : super(key: key);
  DatabaseReference ref;
  final String partyCode;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool _scanning = false;
  String _homeID = "";
  List<double> _guestsInside = [];

  ScreenshotController screenshotController = ScreenshotController();

  String _message = "Scan Code";
  Color _messageColor = Colors.redAccent;

  Future<List<int>> get_Guest_List() async {
    List<int> guestlist = [];

    await widget.ref.child(widget.partyCode).once().then((DataSnapshot data) {
      for (int i = 0; i < data.value.length; i++) {
        guestlist.add(data.value[i]);
      }
    });

    return guestlist;
  }

  Future<void> update_list(int Id) async {
    List<int> temp = await get_Guest_List();
    temp.add(Id);
    widget.ref.child(widget.partyCode).set(temp);
  }

  shareCode() async {
    var rng = new Random();

    String inviteID = DateTime.now().microsecondsSinceEpoch.toString() + rng.nextInt(100).toString();
    await update_list(int.parse(inviteID));

    screenshotController
        .captureFromWidget(
      QrImage(
        data: inviteID,
        version: QrVersions.auto,
      ),
    )
        .then((image) async {
      final directory = (await getApplicationDocumentsDirectory()).path;
      File imgFile = new File('$directory/photo.png');
      await imgFile.writeAsBytes(image);
      await Share.shareFiles(
        [imgFile.path],
      );
    }).catchError((onError) {
      print(onError);
    });

    setState(() {});
  }

  Future<void> scandata(Barcode result) async {
    List<int> _guestlist = await get_Guest_List();

    _scanning = true;

    print(result.code);

    if (_guestsInside.contains(double.parse(result.code))) {
      _messageColor = Colors.orangeAccent;
      _message = "Reused Code";
    }

    if (_guestlist.contains(int.parse(result.code)) && !_guestsInside.contains(double.parse(result.code))) {
      // _guestsInside.add(double.parse(result.code));
      setState(() {
        _messageColor = Colors.green;
        _message = "Approved";
      });
    }

    if (!_guestlist.contains(double.parse(result.code))) {
      setState(() {
        _messageColor = Colors.orangeAccent;
        _message = "Rejected";
      });
    }

    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _scanning = false;
      _message = "Scan Code";
      _messageColor = Colors.redAccent;
    });
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
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
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
          )
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
          widget.partyCode.toUpperCase(),
          style: TextStyle(fontSize: 25),
        ),
        leadingWidth: 80,
        leading: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 90),
              child: GestureDetector(
                onDoubleTap: () {
                  ref.child(widget.partyCode).set([1000, 111, 1111, 111]);
                },
                onTap: () {
                  ref.child(widget.partyCode).once().then((DataSnapshot data) {
                    print(data.value[0]);
                  });
                },
                child: QrImage(
                  size: 300,
                  data: _homeID,
                  foregroundColor: Colors.white,
                  version: QrVersions.auto,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 90),
              child: CupertinoButton(
                  color: Colors.redAccent,
                  child: Text("Send Invite"),
                  onPressed: () {
                    shareCode();
                  }),
            ),
            FutureBuilder(
              future: get_Guest_List(),
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    snapshot.data.length.toString() + " Invitations Sent",
                    style: TextStyle(fontSize: 30, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  );
                }

                return Text("");
              },
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50, top: 30),
              child: Text(
                _guestsInside.length.toString() + " People Inside",
                style: TextStyle(fontSize: 30, color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            )
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
}
