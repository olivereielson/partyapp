import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:bouncer/login.dart';
import 'package:bouncer/partySettings.dart';
import 'package:bouncer/partyStructure.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
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
  FirebaseAnalytics analytics = FirebaseAnalytics();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.dark(),
      ),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
      home: LoginPage(
        analytics: analytics,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(
      {Key? key,
      required this.partyCode,
      required this.ref,
      required this.partyName,
      required this.analytics})
      : super(key: key);
  DatabaseReference ref;
  final String partyCode;
  final String partyName;
  final FirebaseAnalytics analytics;

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
  bool flash = false;

  ScreenshotController screenshotController = ScreenshotController();

  String _message = "Scan Code";
  Color _messageColor = Colors.redAccent;

  SnackBar warning(String warning) {
    return SnackBar(
      content: Text(
        warning,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.redAccent,
      action: SnackBarAction(
        label: 'ok',
        textColor: Colors.white,
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    );
  }

  Future<void> updateParty() async {
    await widget.ref.child(widget.partyName).once().then((DataSnapshot data) {
      //print(data.value);
      if (data.value != null) {
        party.fromjson(json.decode(data.value));
      } else {
        print("party instance created in firebase");
        String str = json.encode(party.toJson());
        widget.ref.child(widget.partyName).set(str);
      }
    });
    setState(() {});
  }

  Future<void> uploadParty() async {
    String str = json.encode(party.toJson());
    widget.ref.child(widget.partyName).set(str);
  }

  shareCode() async {
    String id = party.generateId();
    party.guestList.add(id);
    await uploadParty();

    screenshotController
        .captureFromWidget(
      Container(
        height: 200,
        width: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.redAccent,
        ),
        child: Stack(
          children: [
            Positioned(
              child: Text(
                "id:" + id,
                style: TextStyle(
                    color: Colors.white.withOpacity(
                      0.6,
                    ),
                    fontSize: 7),
              ),
              bottom: 5,
              right: 5,
            ),
            Center(
              child: QrImage(
                data: id,
                foregroundColor: Colors.white,
                version: QrVersions.auto,
              ),
            ),
          ],
        ),
      ),
    )
        .then((image) async {
      final directory = (await getApplicationDocumentsDirectory()).path;
      File imgFile = new File('$directory/photo.png');
      await imgFile.writeAsBytes(image);
      await Share.shareFiles([imgFile.path],
          text: "Show this code to get in to the party");
    }).catchError((onError) {
      print(onError);
    });

    setState(() {});
  }

  Future<void> scandata(Barcode result) async {
    _scanning = true;
    await updateParty();

    print(result.code);
    print(party.guestList);

    if (party.isInside(result.code)) {
      _messageColor = Colors.orangeAccent;
      _message = "Reused Code";
      widget.analytics.logEvent(
        name: 'invite_scanned',
        parameters: <String, dynamic>{
          'outcome': 'reused',
        },
      );
    }

    if (party.onguestList(result.code) && !party.isInside(result.code)) {
      party.guestsInside.add(result.code);
      setState(() {
        _messageColor = Colors.green;
        _message = "Approved";
        widget.analytics.logEvent(
          name: 'invite_scanned',
          parameters: <String, dynamic>{
            'outcome': 'approved',
          },
        );
      });
    }

    if (!party.onguestList(result.code)) {
      setState(() {
        _messageColor = Colors.orangeAccent;
        _message = "Rejected";
        widget.analytics.logEvent(
          name: 'invite_scanned',
          parameters: <String, dynamic>{
            'outcome': 'rejected',
          },
        );
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
      body: Stack(
        children: <Widget>[
          Stack(
            children: [
              QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
            ],
          ),
          Container(
            height: 180,
            width: MediaQuery.of(context).size.width,
            decoration: new BoxDecoration(
                color: _messageColor.withOpacity(0.9),
                borderRadius: new BorderRadius.only(
                  bottomLeft: const Radius.circular(40.0),
                  bottomRight: const Radius.circular(40.0),
                )),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: () async {
                      await controller!.flipCamera();
                      await controller!.resumeCamera();

                      CameraFacing cf = await controller!.getCameraInfo();

                      widget.analytics.logEvent(
                        name: 'camera_flipped',
                        parameters: <String, dynamic>{
                          'front': cf == CameraFacing.back ? true : false,
                        },
                      );
                    },
                    icon: Icon(
                      Icons.flip_camera_ios_rounded,
                      size: 30,
                      color: Colors.white,
                    )),
                Text(
                  _message,
                  style: TextStyle(fontSize: 30),
                ),
                SafeArea(
                  child: IconButton(
                      onPressed: () async {
                        flash = (await controller!.getFlashStatus())!;

                        if (await controller!.getCameraInfo() ==
                            CameraFacing.back) {
                          await controller!.toggleFlash();
                          widget.analytics.logEvent(
                            name: 'flash_toggled',
                            parameters: <String, dynamic>{
                              'flash': flash,
                              'success': true
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(warning(
                              "Flash can only be used with front camera"));
                          widget.analytics.logEvent(
                            name: 'flash_toggled',
                            parameters: <String, dynamic>{
                              'flash': flash,
                              'success': false
                            },
                          );
                        }

                        flash = (await controller!.getFlashStatus())!;
                        setState(() {});
                      },
                      icon: Icon(
                          flash ? Icons.flashlight_on : Icons.flashlight_off)),
                ),
              ],
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
            Navigator.push(
                context,
                PageTransition(
                    type: PageTransitionType.topToBottom,
                    duration: Duration(milliseconds: 500),
                    child: LoginPage(
                      analytics: widget.analytics,
                    )));
          },
        ),
        actions: [
          TextButton(
              onPressed: () {
                shareCode();
                widget.analytics.logEvent(
                  name: 'invite_sent',
                );
              },
              child: Text(
                "Invite",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold),
              ))
        ],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 90),
              child: Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width - 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.redAccent,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          child: Text(
                            "Invite Card",
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.transparent),
                          ),
                          top: 5,
                          left: 5,
                        ),
                        Positioned(
                          child: IconButton(
                            icon: Icon(Icons.info),
                            onPressed: () {
                              widget.analytics.logEvent(
                                name: 'info_card_clicked',
                              );

                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.redAccent,
                                    elevation: 50,
                                    title: Text("Invite Card"),
                                    content: Text(
                                        "Any user who scans this code with the app will be given a invite code"),
                                    actions: [
                                      TextButton(
                                        child: Text(
                                          "OK",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      )
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          top: 5,
                          right: 5,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Center(
                            child: QrImage(
                              size: 200,
                              data: "${party.partyName},${party.partyCode}",
                              foregroundColor: Colors.white,
                              version: QrVersions.auto,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: CupertinoButton(
                  color: Colors.transparent,
                  child: Text(
                    "Send Invite",
                    style: TextStyle(
                        color: Colors.transparent, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {}),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 20),
                            child: Text(
                              "Party Info",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 30),
                            ),
                          ),

                          IconButton(onPressed: (){

                            Navigator.push(context, PageTransition(type: PageTransitionType.fade, child: party_settings(widget.analytics)));



                          }, icon: Icon(Icons.settings,color: Colors.white,))
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Invitations Sent",
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            party.guestList.length.toString(),
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20, top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "People Inside",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              party.guestsInside.length.toString(),
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
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
        physics: ClampingScrollPhysics(),
        controller: PageController(keepPage: true),
        scrollDirection: Axis.vertical,
        children: [page1(widget.ref), page2()],
      ),
    );
  }

  @override
  void initState() {
    party = Party(
        partyCode: widget.partyCode,
        partyName: widget.partyName,
        guestsInside: [],
        guestList: []);
    updateParty();
    _testSetCurrentScreen();
    super.initState();
  }

  Future<void> _testSetCurrentScreen() async {
    await widget.analytics.setCurrentScreen(
      screenName: 'Party Home Page',
      screenClassOverride: 'Party Home Page',
    );
  }
}
