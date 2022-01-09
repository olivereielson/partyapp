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
import 'package:card_swiper/card_swiper.dart';
import 'package:card_swiper/card_swiper.dart';
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
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'User.dart';
import 'createparty.dart';
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
      routes: {
        'login': (context) => LoginPage(analytics: analytics),
        'create': (context) => CreateParty(
              analytics: analytics,
            ),
      },
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

  bool dead = false;

  success(String message) {
    showTopSnackBar(
      context,
      CustomSnackBar.success(
        message: message,
      ),
    );
  }

  warning(String message) {
    showTopSnackBar(
        context,
        CustomSnackBar.error(
          message: message,
        ),
        displayDuration: Duration(milliseconds: 200));
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
    if (_connectionStatus != ConnectivityResult.none) {
      final Trace trace = _performance.newTrace('share_trace');
      await trace.start();

      if (cashId == "" || cashPath == "") {
        await Storecode;
      }

      party.set({cashId: _reuse}, SetOptions(merge: true));

      party.set({"invites": FieldValue.increment(1)}, SetOptions(merge: true));

      await Share.shareFiles([cashPath],
          text:
              "Save in App:PartyLabs://PartyLabsInviteCodeLink.com/${cashId}");

      setState(() {});

      cashPath = "";
      cashId = "";
      Storecode();
      await trace.stop();
    } else {
      warning("No Internet Connection");
    }
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
                      "Invite Requests",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        "Accept or Deny a user requests for an invite.",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              ))
        ]));

    targets.add(TargetFocus(identify: "Target 2", keyTarget: keyButton2, contents: [
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
        colorShadow: Colors.redAccent,
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
    })..show();
  }

  void acceptInvite(String name) {
    //name=name.substring(1);

    try {
      String id = generateID();
      FirebaseFirestore.instance
          .collection('accepted')
          .doc(widget.partyName)
          .set({name: id}, SetOptions(merge: true));
      FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.partyName)
          .set({name: FieldValue.delete()}, SetOptions(merge: true));
      FirebaseFirestore.instance
          .collection('party')
          .doc(widget.partyName)
          .set({id: _reuse}, SetOptions(merge: true));

      FirebaseFirestore.instance
          .collection('party')
          .doc(widget.partyName)
          .set({"invites": FieldValue.increment(1)}, SetOptions(merge: true));

      success("Invite Accepted");
    } catch (exeption) {
      warning("Unknown Error Occurred");
    }
  }

  void rejectInvite(String name) {
    try {
      FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.partyName)
          .set({name.split(":")[0]: FieldValue.delete()},
              SetOptions(merge: true));
      warning("Request Rejected");
    } catch (e) {
      warning("Unknown Error Occurred");
    }
  }

  Widget inviteStream() {
    return Container(
      key: keyButton,
      child: _connectionStatus == ConnectivityResult.none
          ? Padding(
              padding: const EdgeInsets.all(15.0),
              child: Container(
                height: 210,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  // color: Colors.redAccent,
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.pink,
                      Colors.red,
                    ],
                  ),
                ),
                child: Center(
                    child: Text(
                  "No Internet Connection",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                )),
              ),
            )
          : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .doc(widget.partyName)
                  .snapshots(),
              builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.data().toString().length > 2 &&
                      snapshot.data!.data().toString() != "null") {
                    List<String> Data = snapshot.data!
                        .data()
                        .toString()
                        .substring(
                            1, snapshot.data!.data().toString().length - 1)
                        .split(",");
                    return Container(
                      height: 210,
                      width: MediaQuery.of(context).size.width,
                      child: Swiper(
                        itemBuilder: (BuildContext context, int index) {
                          return Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                // color: Colors.redAccent,
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Colors.pink,
                                    Colors.red,
                                  ],
                                ),
                              ),
                              width: MediaQuery.of(context).size.width,
                              child: Center(
                                  child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30),
                                      child: Row(
                                        children: [
                                          Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: Color.fromRGBO(
                                                    40, 40, 40, 1),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Image.asset(
                                                  "assets/logo_white.png",
                                                  height: 40,
                                                  color: Colors.redAccent,
                                                ),
                                              )),
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: AutoSizeText(
                                                Data[index].split(":")[0],
                                                maxLines: 2,
                                                minFontSize: 20,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: CupertinoButton(
                                            onPressed: () => rejectInvite(
                                                Data[index].split(":")[0]),
                                            child: Text("Reject",
                                                style: TextStyle(
                                                    color: Colors.redAccent,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            color:
                                                Color.fromRGBO(60, 60, 60, 1),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 30),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: CupertinoButton(
                                            onPressed: () => acceptInvite(
                                                Data[index].split(":")[0]),
                                            child: Text(
                                              "Accept",
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            color:
                                                Color.fromRGBO(60, 60, 60, 1),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 60),
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              )),
                            ),
                          );
                        },
                        itemCount: Data.length,
                        containerHeight: MediaQuery.of(context).size.width,
                        containerWidth: 200,
                        loop: true,
                        onTap: (int) {
                          print(int);
                        },
                        pagination: new SwiperPagination(
                            margin: new EdgeInsets.all(0.0),
                            builder: new DotSwiperPaginationBuilder(
                                color: Colors.transparent,
                                activeColor: Colors.transparent,
                                space: 20,
                                size: 5.0,
                                activeSize: 7.0)),
                        control: new SwiperControl(
                          color: Colors.transparent,
                          disableColor: Colors.transparent,
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Container(
                      height: 210,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            //CupertinoColors.systemPink,
                            Colors.pink,
                            Colors.red,
                          ],
                        ),
                        border: Border.all(color: Colors.transparent, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          "No Invite Requests",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                    ),
                  );
                }

                return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent, width: 3),
                    ),
                    child: Center(child: Text("Loading")));
              },
            ),
    );
  }

  Widget statStream() {
    print(dead);
    if (dead) {
      return Container();
    }

    return Container(
      decoration: new BoxDecoration(
          //  color: Colors.grey.withOpacity(0.1),
          //color: Colors.white10,
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              //CupertinoColors.systemPink,
              Colors.pink,
              Colors.red,
            ],
          ),
          borderRadius: new BorderRadius.only(
            topLeft: const Radius.circular(20.0),
            topRight: const Radius.circular(20.0),
            //   bottomRight: const Radius.circular(20.0),
            //   / bottomLeft: const Radius.circular(20.0),
          )),
      width: MediaQuery.of(context).size.width,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: _connectionStatus == ConnectivityResult.none
              ? Center(
                  child: Text(
                  "No Internet Connection",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ))
              : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('party').doc(widget.partyName)
                      .snapshots(),
                  key: keyButton3,
                  builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Something went wrong'));
                    }

                    if (snapshot.hasData) {
                      return Column(
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 30),
                                ),
                              ),
                              IconButton(
                                  onPressed: () async {
                                    _reuse = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => party_settings(
                                                widget.analytics,
                                                partyName: widget.partyName,
                                                partyCode: widget.partyCode,
                                                reuse: _reuse,
                                              )),
                                    );

                                    if (_reuse == -1) {

                                      dead=true;
                                      Navigator.pop(context);

                                      FirebaseFirestore.instance.collection('party').doc(widget.partyName).delete().then((value) {
                                      });
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
                          /*
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
                              snapshot.data!.get("invites").toString(),
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                      */
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20, top: 0),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    }
                    return Center(child: Text('Something went wrong'));
                  })),
    );
  }

  Widget centerCode() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 50),
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          //color: Colors.redAccent,
          border: Border.all(color: Colors.redAccent, width: 3),
        ),
        child: Stack(
          children: [
            Positioned(
                top: 10,
                left: 10,
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Color.fromRGBO(40, 40, 40, 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        "assets/logo_white.png",
                        height: 30,
                        color: Colors.redAccent,
                      ),
                    ))),
            Positioned(
                right: 10,
                child: IconButton(
                  icon: Icon(CupertinoIcons.share),
                  onPressed: () {
                    shareCode(FirebaseFirestore.instance
                        .collection("party")
                        .doc(widget.partyName));
                  },
                )),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: QrImage(
                  data: "test",
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget topBar() {
    if (dead) {
      return Container();
    }

    return Container(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('party')
            .doc(widget.partyName)
            .snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      //CupertinoColors.systemPink,
                      Colors.pink,
                      Colors.red,
                    ],
                  ),
                  border: Border.all(color: Colors.transparent, width: 3),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      Text(
                        snapshot.data!.get("invites") == 1
                            ? "1 Invite"
                            : snapshot.data!.get("invites").toString() +
                                " Invites",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 30),
                      ),
                      Spacer(),
                      IconButton(
                        key: keyButton2,
                        icon: Icon(CupertinoIcons.share),
                        onPressed: () {
                          shareCode(FirebaseFirestore.instance
                              .collection("party")
                              .doc(widget.partyName));
                        },
                      )
                    ],
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    //CupertinoColors.systemPink,
                    Colors.pink,
                    Colors.red,
                  ],
                ),
                border: Border.all(color: Colors.transparent, width: 3),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    Text(
                      "Loading",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(
                        CupertinoIcons.share,
                        color: Colors.white10,
                      ),
                      onPressed: () {
                        shareCode(FirebaseFirestore.instance
                            .collection("party")
                            .doc(widget.partyName));
                      },
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          body: Container(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // centerCode(),

                Flexible(flex: 6, child: topBar()),
                Flexible(flex: 1, child: Container()),
                Flexible(flex: 6, child: inviteStream()),
                Flexible(flex: 1, child: Container()),

                Spacer(),

                Flexible(flex: 8, child: statStream()),
              ],
            ),
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
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
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
