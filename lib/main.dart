import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:auto_size_text_pk/auto_size_text_pk.dart';
import 'package:bouncer/login.dart';
import 'package:bouncer/partySettings.dart';
import 'package:bouncer/partyStructure.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
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
      home: Userpage(
        analytics: analytics,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(
      {Key? key,
      required this.partyCode,
      required this.partyName,
      required this.analytics})
      : super(key: key);
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
  bool flash = false;
  int _reuse = 1;

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

  String generateID() {
    var rng = new Random();

    String date = DateTime.now().microsecondsSinceEpoch.toString();

    String inviteID = widget.partyName.toUpperCase() +
        "-" +
        date.substring(date.length - 5) +
        "-" +
        rng.nextInt(100000).toString();

    print(inviteID);

    return inviteID;
  }

  shareCode(DocumentReference party) async {
    String id = generateID();

    party.set({id: _reuse}, SetOptions(merge: true));

    party.get().then((DocumentSnapshot documentSnapshot) {
      party.set({"invites": documentSnapshot.get("invites") + 1},
          SetOptions(merge: true));
    });

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

  Future<void> scandata(Barcode result, DocumentReference party) async {
    _scanning = true;

    party.get().then((DocumentSnapshot documentSnapshot) {
      try {
        if (documentSnapshot.get(result.code) == 0) {
          _messageColor = Colors.orangeAccent;
          _message = "Reused Code";
          widget.analytics.logEvent(
            name: 'invite_scanned',
            parameters: <String, dynamic>{
              'outcome': 'reused',
            },
          );
        }

        if (documentSnapshot.get(result.code) != 0 &&
            documentSnapshot.get(result.code) != null) {
          party.get().then((DocumentSnapshot documentSnapshot) {
            if (documentSnapshot.get(result.code) > 1) {
              party.set({result.code: documentSnapshot.get(result.code) - 1},
                  SetOptions(merge: true));
            } else {
              party.set({result.code: 0}, SetOptions(merge: true));
            }
          });

          party.get().then((DocumentSnapshot documentSnapshot) {
            party.set({"scans": documentSnapshot.get("scans") + 1},
                SetOptions(merge: true));
          });

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
      } catch (e) {
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
    });

    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _message = "Scan Code";
      _messageColor = Colors.redAccent;
    });
    _scanning = false;
  }

  void _onQRViewCreated(QRViewController controller, DocumentReference party) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      if (!_scanning) {
        scandata(result!, party);
      }
    });
  }

  Scaffold page2() {
    DocumentReference party =
        FirebaseFirestore.instance.collection('party').doc(widget.partyName);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          Stack(
            children: [
              QRView(
                  key: qrKey,
                  onQRViewCreated: (cont) {
                    return _onQRViewCreated(cont, party);
                  }),
            ],
          ),
          Positioned(
            bottom: 0,
            child: Container(
              height: 180,
              width: MediaQuery.of(context).size.width,
              decoration: new BoxDecoration(
                  color: _messageColor.withOpacity(0.9),
                  borderRadius: new BorderRadius.only(
                    topLeft: const Radius.circular(40.0),
                    topRight: const Radius.circular(40.0),
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
                        icon: Icon(flash
                            ? Icons.flashlight_on
                            : Icons.flashlight_off)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Scaffold page1() {
    DocumentReference party =
        FirebaseFirestore.instance.collection('party').doc(widget.partyName);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: AutoSizeText(
          widget.partyName,
          maxLines: 1,
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
                    child: Userpage(
                      analytics: widget.analytics,
                    )));
          },
        ),
        actions: [
          TextButton(
              onPressed: () {
                shareCode(party);
                widget.analytics.logEvent(
                  name: 'invite_sent',
                );
              },
              child: Text(
                "Invite",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold,fontSize: 15),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width - 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent, width: 3),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(00),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: Offset(0, 3), // changes position of shadow
                        ),
                      ],
                      // color: Colors.redAccent,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                            top: 15,
                            left: 15,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color.fromRGBO(43, 43, 43, 1),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  "assets/logo_white.png",
                                  width: 20,
                                  color: Colors.redAccent.withOpacity(1),
                                ),
                              ),
                            )),
                        Positioned(
                          bottom: 10,
                          child: Text(
                            "Invite Card",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.8)),
                          ),
                          right: 10,
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
                              data:
                                  "${widget.partyName},${widget.partyCode},$_reuse",
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
                    color: Colors.grey.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.transparent,
                      width: 5,
                    ),
                    borderRadius: new BorderRadius.only(
                      topLeft: const Radius.circular(40.0),
                      topRight: const Radius.circular(40.0),
                     // bottomRight: const Radius.circular(40.0),
                      //bottomLeft: const Radius.circular(40.0),
                    )),
                width: MediaQuery.of(context).size.width,
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('party')
                            .doc(widget.partyName)
                            .snapshots(),
                        builder: (context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return Text('Something went wrong');
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text("Loading");
                          }

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 20),
                                    child: Text(
                                      "Party Info",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 30),
                                    ),
                                  ),
                                  IconButton(
                                      onPressed: () async {
                                        _reuse= await Navigator.push(
                                            context,
                                            PageTransition(
                                                type: PageTransitionType.fade,
                                                child: party_settings(
                                                  widget.analytics,
                                                  partyName: widget.partyName,
                                                  partyCode: widget.partyCode,
                                                  reuse: _reuse,
                                                )));

                                        setState(() {

                                        });

                                      },
                                      icon: Icon(
                                        Icons.settings,
                                        color: Colors.white,
                                      ))
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Invitations Sent",
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    snapshot.data!.get("invites").toString(),
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 20, top: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "People Inside",
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      snapshot.data!.get("scans").toString(),
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Scans Per Invite",
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _reuse.toString(),
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),


                            ],
                          );
                        })),
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
        children: [page1(), page2()],
      ),
    );
  }

  @override
  void initState() {
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
