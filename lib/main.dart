import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:auto_size_text_pk/auto_size_text_pk.dart';
import 'package:bouncer/login.dart';
import 'package:bouncer/partySettings.dart';
import 'package:bouncer/partyStructure.dart';
import 'package:bouncer/rootScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share/share.dart';
import 'package:share_files_and_screenshot_widgets_plus/share_files_and_screenshot_widgets_plus.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'User.dart';
import 'hostScan.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runZonedGuarded(() {
    runApp(MyApp());
  }, FirebaseCrashlytics.instance.recordError);
}

GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  FirebaseAnalytics analytics = FirebaseAnalytics();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: mainNavigatorKey,
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.dark(),
      ),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
      home: rootScreen(
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
  List<TargetFocus> targets = [];
  QRViewController? controller;
  bool _scanning = false;
  String _homeID = "";
  bool flash = false;
  int _reuse = 1;
  String cashId = "";
  String cashPath = "";
  ScreenshotController screenshotController = ScreenshotController();
  FirebasePerformance _performance = FirebasePerformance.instance;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;



  GlobalKey keyButton = GlobalKey();
  GlobalKey keyButton1 = GlobalKey();
  GlobalKey keyButton2 = GlobalKey();
  GlobalKey keyButton3 = GlobalKey();
  GlobalKey keyButton4 = GlobalKey();
  GlobalKey keyButton5 = GlobalKey();

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

  shareCode2(DocumentReference party) async {
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

  shareCode(DocumentReference party) async {
    final Trace trace = _performance.newTrace('share_trace');
    await trace.start();

    if (cashId == "" || cashPath == "") {
      await Storecode;
    }

    party.set({cashId: _reuse}, SetOptions(merge: true));

    party.get().then((DocumentSnapshot documentSnapshot) {
      party.set({"invites": documentSnapshot.get("invites") + 1},
          SetOptions(merge: true));
    });

    await Share.shareFiles([cashPath],
        text: "Save in App:PartyLabs://PartyLabsInviteCodeLink.com/${cashId}");

    setState(() {});

    cashPath = "";
    cashId = "";
    Storecode();
    await trace.stop();
  }

  Storecode() async {
    String id = generateID();
    cashId = id;
    await screenshotController
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
      cashPath = imgFile.path;
    });
  }

  void createTargets() {
    targets.add(TargetFocus(
        identify: "Target 1",
        keyTarget: keyButton,
        shape: ShapeLightFocus.RRect,
        radius: 20,
        contents: [
          TargetContent(
              align: ContentAlign.bottom,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Invite Card",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        "Users can scan this card to have an invite added to their saved passes.  Never send a user a screenshot of this code",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              ))
        ]));
    targets.add(
        TargetFocus(identify: "Target 2", keyTarget: keyButton2, contents: [
      TargetContent(
          align: ContentAlign.bottom,
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Send Code",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    "This lets you send users an invite code. Each user needs their own code.",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
          ))
    ]));

    targets.add(TargetFocus(
        identify: "Target 3",
        keyTarget: keyButton3,
        shape: ShapeLightFocus.RRect,
        radius: 20,
        contents: [
          TargetContent(
              align: ContentAlign.top,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Party Info",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        "This lets you track how many people you have invited and how many people you have scanned in. You can also see how many times the code you are sending can be scanned before it will be rejected (the default is 1). ",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              ))
        ]));

    targets.add(
        TargetFocus(identify: "Target 4", keyTarget: keyButton4, contents: [
      TargetContent(
          align: ContentAlign.bottom,
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Control Party Settings",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    "This lets you track how many people you have invited and how many people you have scanned in. You can also see how many times the code you are sending can be scanned before it will be rejected (the default is 1). ",
                    style: TextStyle(color: Colors.white.withOpacity(0)),
                  ),
                )
              ],
            ),
          ))
    ]));

    targets.add(
        TargetFocus(identify: "Target 5", keyTarget: keyButton5, contents: [
      TargetContent(
          align: ContentAlign.bottom,
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Scan Codes",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20.0),
                ),
              ],
            ),
          ))
    ]));
  }

  void showTutorial() {
    TutorialCoachMark tutorial = TutorialCoachMark(context,
        targets: targets,
        // List<TargetFocus>
        colorShadow: Colors.red,
        // DEFAULT Colors.black
        alignSkip: Alignment.topLeft,
        textSkip: "SKIP",
        // paddingFocus: 10,
        // focusAnimationDuration: Duration(milliseconds: 500),
        // pulseAnimationDuration: Duration(milliseconds: 500),
        // pulseVariation: Tween(begin: 1.0, end: 0.99),
        onFinish: () {
      print("finish");
    }, onClickTarget: (target) {
      print(target);
    }, onSkip: () {
      widget.analytics.logEvent(
        name: 'info_skipped',
      );
    })
      ..show();
  }

  @override
  Widget build(BuildContext context) {
    DocumentReference party =
        FirebaseFirestore.instance.collection('party').doc(widget.partyName);
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
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
                onPressed: () {
                  widget.analytics.logEvent(
                    name: 'info_button_clicked',
                  );
                  targets.clear();
                  createTargets();
                  showTutorial();
                },
                icon: Icon(
                  CupertinoIcons.info,
                  size: 30,
                )),
            actions: [
              IconButton(
                key: keyButton5,
                icon: Icon(
                  Icons.qr_code_scanner_outlined,
                  size: 30,
                ),
                onPressed: () {
                  pushNewScreen(
                    context,
                    screen: HostScan(
                      partyName: widget.partyName,
                      partyCode: widget.partyCode,
                      analytics: widget.analytics,
                    ),
                    withNavBar: false,
                    pageTransitionAnimation: PageTransitionAnimation.cupertino,
                  );
                },
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 1, child: Container()),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: Container(
                    key: keyButton,
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
                                color: Colors.grey.withOpacity(0.1),
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
                          child: IconButton(
                            key: keyButton2,
                            icon: Icon(CupertinoIcons.share),
                            onPressed: () {
                              shareCode(party);
                              widget.analytics.logEvent(
                                name: 'invite_sent',
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
                ),
              ),
              Expanded(flex: 2, child: Container()),
              Expanded(
                flex: 4,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child:_connectionStatus==ConnectivityResult.none?Center(child: Text("No Internet Connection")):StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('party')
                              .doc(widget.partyName)
                              .snapshots(),
                          key: keyButton3,
                          builder: (context,
                              AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Something went wrong'));
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: Text("Loading"));
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
                                          _reuse = await Navigator.push(
                                              context,
                                              PageTransition(
                                                  type: PageTransitionType.fade,
                                                  child: party_settings(
                                                    widget.analytics,
                                                    partyName: widget.partyName,
                                                    partyCode: widget.partyCode,
                                                    reuse: _reuse,
                                                  )));

                                          if (_reuse == -1) {
                                            Navigator.pop(context);
                                          }

                                          setState(() {});
                                        },
                                        key: keyButton4,
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
                                  padding: const EdgeInsets.only(
                                      bottom: 20, top: 20),
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
        ));
  }

  @override
  void initState() {
    _testSetCurrentScreen();
    createTargets();
    super.initState();
    Storecode();
    initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _testSetCurrentScreen() async {
    await widget.analytics.setCurrentScreen(
      screenName: 'Party Home Page',
      screenClassOverride: 'Party_Home_Page',
    );
  }

  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
      return;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {

    setState(() {
      _connectionStatus = result;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

}
