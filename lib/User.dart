import 'package:bouncer/UserScan.dart';
import 'package:bouncer/login.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:page_transition/page_transition.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'headers.dart';

class Userpage extends StatefulWidget {
  final FirebaseAnalytics analytics;

  Userpage({required this.analytics});

  @override
  _UserpageState createState() => _UserpageState();
}

class _UserpageState extends State<Userpage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR2');
  Barcode? result;
  QRViewController? controller;

  Scaffold savedInvites2() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            child: ClipPath(
              clipper: ProsteThirdOrderBezierCurve(
                position: ClipPosition.top,
                list: [
                  ThirdOrderBezierCurveSection(
                    p1: Offset(0, 100),
                    p2: Offset(150, 300),
                    p3: Offset(200, 200),
                    p4: Offset(0, 206),
                  ),
                ],
              ),
              child: Container(
                height: 350,
                width: MediaQuery.of(context).size.width,
                color: Colors.redAccent,
              ),
            ),
          ),
          SafeArea(
            bottom: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 20, 30, 0),
                  child: Row(
                    children: [
                      Text(
                        "Saved Passes",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 35,
                            fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      IconButton(
                          onPressed: () async {
                            String id = await Navigator.push(
                                context,
                                PageTransition(
                                    type: PageTransitionType.topToBottom,
                                    child: UserScan(
                                      analytics: widget.analytics,
                                    )));

                            if (id != "0") {
                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();

                              if (prefs.containsKey("wallet")) {
                                List<String>? codes =
                                    prefs.getStringList("wallet");
                                codes!.add(id);
                                prefs.setStringList("wallet", codes);
                              } else {
                                prefs.setStringList("wallet", [id]);
                              }

                              setState(() {});
                            }
                          },
                          icon: Icon(
                            Icons.qr_code_scanner_outlined,
                            size: 30,
                          ))
                    ],
                  ),
                ),
                Container(
                    width: MediaQuery.of(context).size.width,
                    height: 250,
                    child: FutureBuilder(
                      future: pref(),
                      builder: (BuildContext context,
                          AsyncSnapshot<SharedPreferences> snapshot) {
                        if (snapshot.hasData &&
                            snapshot.data!.getStringList("wallet") != null) {
                          if (snapshot.data!.getStringList("wallet")!.length ==
                              0) {
                            return Padding(
                              padding: const EdgeInsets.all(30.0),
                              child: Container(
                                height: 100,
                                width: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.redAccent,
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                        child: Text(
                                      "No Saved Cards",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    )),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Swiper(
                            itemBuilder: (BuildContext context, int index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: GestureDetector(
                                  onLongPress: () {
                                    widget.analytics.logEvent(
                                        name: "user_card_long_pressed");
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          CupertinoAlertDialog(
                                        title: Text("Delete Pass?"),
                                        content: Text(
                                            "This action can not be undone"),
                                        actions: <Widget>[
                                          CupertinoButton(
                                              child: Text(
                                                "Cancel",
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);
                                              }),
                                          CupertinoButton(
                                              child: Text(
                                                "Delete",
                                                style: TextStyle(
                                                    color: Colors.redAccent),
                                              ),
                                              onPressed: () async {
                                                SharedPreferences prefs =
                                                    await SharedPreferences
                                                        .getInstance();

                                                if (prefs
                                                    .containsKey("wallet")) {
                                                  List<String>? codes = prefs
                                                      .getStringList("wallet");
                                                  codes!.removeAt(index);
                                                  prefs.setStringList(
                                                      "wallet", codes);
                                                } else {
                                                  prefs.setStringList(
                                                      "wallet", []);
                                                }
                                                widget.analytics.logEvent(
                                                    name: "user_card_deleted");
                                                setState(() {});
                                                Navigator.pop(context);
                                              }),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 100,
                                    width: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.redAccent,
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipPath(
                                          clipper: ProsteThirdOrderBezierCurve(
                                            position: ClipPosition.top,
                                            list: [
                                              ThirdOrderBezierCurveSection(
                                                p1: Offset(0, 150),
                                                p2: Offset(150, 260),
                                                p3: Offset(0, 180),
                                                p4: Offset(0, 150),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              //color: Color.fromRGBO(43, 43, 43, 1),
                                              //color: Colors.black.withOpacity(0/9)
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                            left: 5,
                                            bottom: 5,
                                            child: Image.asset(
                                              "assets/logo_white.png",
                                              width: 30,
                                              color:
                                                  Colors.white.withOpacity(0),
                                            )),
                                        Positioned(
                                          child: Text(
                                            snapshot.data!.getStringList(
                                                "wallet")![index],
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                                fontSize: 10),
                                          ),
                                          bottom: 5,
                                          right: 5,
                                        ),
                                        Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              QrImage(
                                                size: 170,
                                                data: snapshot.data!
                                                    .getStringList(
                                                        "wallet")![index],
                                                foregroundColor: Colors.white,
                                                version: QrVersions.auto,
                                              ),
                                              Text(
                                                "Party Labs",
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            itemCount: snapshot.data!.getStringList("wallet") !=
                                    null
                                ? snapshot.data!.getStringList("wallet")!.length
                                : 0,
                            pagination: DotSwiperPaginationBuilder(
                                color: Colors.transparent,
                                activeColor: Colors.transparent),
                            loop: false,
                            control: SwiperControl(
                                color: Colors.transparent,
                                disableColor: Colors.transparent),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Container(
                            height: 100,
                            width: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.redAccent,
                            ),
                            child: Stack(
                              children: [
                                Center(
                                    child: Text(
                                  "No Saved Cards",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                )),
                              ],
                            ),
                          ),
                        );
                        ;
                      },
                    )),
                Padding(
                  padding: const EdgeInsets.only(top: 60, bottom: 10),
                  child: CupertinoButton(
                      //color: Color.fromRGBO(43, 43, 43, 1),
                      color: Colors.transparent,
                      child: Text(
                        "Host Party",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.topToBottom,
                              child: LoginPage(
                                analytics: widget.analytics,
                              ),
                            ));
                      }),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget savedInvitese() {
    return FutureBuilder(
      future: pref(),
      builder:
          (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
        if (snapshot.hasData &&
            snapshot.data!.getStringList("wallet") != null) {
          if (snapshot.data!.getStringList("wallet")!.length == 0) {
            return Padding(
              padding: const EdgeInsets.all(30.0),
              child: Container(
                height: 100,
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.redAccent,
                ),
                child: Stack(
                  children: [
                    Center(
                        child: Text(
                      "No Saved Cards",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    )),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onLongPress: () {
                    widget.analytics.logEvent(name: "user_card_long_pressed");
                    showDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: Text("Delete Pass?"),
                        content: Text("This action can not be undone"),
                        actions: <Widget>[
                          CupertinoButton(
                              child: Text(
                                "Cancel",
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              }),
                          CupertinoButton(
                              child: Text(
                                "Delete",
                                style: TextStyle(color: Colors.redAccent),
                              ),
                              onPressed: () async {
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();

                                if (prefs.containsKey("wallet")) {
                                  List<String>? codes =
                                      prefs.getStringList("wallet");
                                  codes!.removeAt(index);
                                  prefs.setStringList("wallet", codes);
                                } else {
                                  prefs.setStringList("wallet", []);
                                }
                                widget.analytics
                                    .logEvent(name: "user_card_deleted");
                                setState(() {});
                                Navigator.pop(context);
                              }),
                        ],
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      height: 200,
                      width: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.redAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 7,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          ClipPath(
                            clipper: ProsteThirdOrderBezierCurve(
                              position: ClipPosition.top,
                              list: [
                                ThirdOrderBezierCurveSection(
                                  p1: Offset(0, 150),
                                  p2: Offset(150, 260),
                                  p3: Offset(0, 180),
                                  p4: Offset(0, 150),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                //color: Color.fromRGBO(43, 43, 43, 1),
                                //color: Colors.black.withOpacity(0/9)
                              ),
                            ),
                          ),
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
                                    width: 30,
                                    color: Colors.redAccent.withOpacity(1),
                                  ),
                                ),
                              )),
                          Positioned(
                            child: Text(
                              snapshot.data!.getStringList("wallet")![index],
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 10),
                            ),
                            bottom: 5,
                            right: 30,
                          ),
                          Center(
                            child: QrImage(
                              size: 150,
                              data: snapshot.data!
                                  .getStringList("wallet")![index],
                              foregroundColor: Colors.white,
                              version: QrVersions.auto,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            itemCount: snapshot.data!.getStringList("wallet") != null
                ? snapshot.data!.getStringList("wallet")!.length
                : 0,
          );
        }

        return Padding(
          padding: const EdgeInsets.all(30.0),
          child: Container(
            height: 100,
            width: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.redAccent,
            ),
            child: Stack(
              children: [
                Center(
                    child: Text(
                  "No Saved Cards",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                )),
              ],
            ),
          ),
        );
        ;
      },
    );
  }

  Widget button() {
    return IconButton(
        onPressed: () async {
          String id = await Navigator.push(
              context,
              PageTransition(
                  type: PageTransitionType.topToBottom,
                  child: UserScan(
                    analytics: widget.analytics,
                  )));

          if (id != "0") {
            SharedPreferences prefs = await SharedPreferences.getInstance();

            if (prefs.containsKey("wallet")) {
              List<String>? codes = prefs.getStringList("wallet");
              codes!.add(id);
              prefs.setStringList("wallet", codes);
            } else {
              prefs.setStringList("wallet", [id]);
            }

            setState(() {});
          }
        },
        icon: Icon(
          Icons.qr_code_scanner_outlined,
          size: 30,
        ));
  }

  Future<SharedPreferences> pref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
            resizeToAvoidBottomInset:false,

            body: PageView(
          scrollDirection: Axis.horizontal,
          physics: ClampingScrollPhysics(),
          children: [
            NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverPersistentHeader(
                    pinned: true,
                    floating: true,
                    delegate: MyDynamicHeader(button()),
                  ),
                ];
              },
              body: savedInvitese(),
            ),
            LoginPage(analytics: widget.analytics),
          ],
        )));
  }

  Future<void> _testSetCurrentScreen() async {
    await widget.analytics.setCurrentScreen(
      screenName: 'User Page',
      screenClassOverride: 'UserPage',
    );
  }

  @override
  void initState() {
    _testSetCurrentScreen();
    super.initState();
  }
}
