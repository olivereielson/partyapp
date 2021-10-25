import 'dart:ui';

import 'package:auto_size_text_pk/auto_size_text_pk.dart';
import 'package:bouncer/UserScan.dart';
import 'package:bouncer/login.dart';
import 'package:bouncer/search.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:page_transition/page_transition.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'headers.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';

class Userpage extends StatefulWidget {
  final FirebaseAnalytics analytics;

  Userpage({required this.analytics});

  @override
  _UserpageState createState() => _UserpageState();
}

class _UserpageState extends State<Userpage>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR2');
  Barcode? result;
  QRViewController? controller;
  late Animation<double> animation;
  late AnimationController _controller;
  PageController pc = PageController(initialPage: 0);
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  //List<bool> expanded = [];
  int _expanded = -1;

  int page = 0;

  void deleteCard(int index) {
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
                SharedPreferences prefs = await SharedPreferences.getInstance();

                if (prefs.containsKey("wallet")) {
                  List<String>? codes = prefs.getStringList("wallet");
                  codes!.removeAt(index);
                  prefs.setStringList("wallet", codes);
                } else {
                  prefs.setStringList("wallet", []);
                }
                widget.analytics.logEvent(name: "user_card_deleted");
                setState(() {});
                Navigator.pop(context);
              }),
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
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 90),
                  child: Container(
                    height: 200,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent, width: 3),
                      color: Colors.transparent,
                    ),
                    child: Stack(
                      children: [
                        Center(
                            child: Text(
                          "No Saved Cards",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Hero(
                    tag: "card$index",
                    child: Card(index, snapshot),
                  ),
                ),
              );
            },
            itemCount: snapshot.data!.getStringList("wallet") != null
                ? snapshot.data!.getStringList("wallet")!.length
                : 0,
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 90),
              child: Container(
                height: 200,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent, width: 3),
                  color: Colors.transparent,
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
            ),
          ],
        );
      },
    );
  }

  Widget button() {
    return IconButton(
        onPressed: () async {
          //FirebaseCrashlytics.instance.crash();

          String id = await pushNewScreen(
            context,
            screen: UserScan(
              analytics: widget.analytics,
            ),
            withNavBar: false, // OPTIONAL VALUE. True by default.
            pageTransitionAnimation: PageTransitionAnimation.cupertino,
          );

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

  Widget Card(int index, AsyncSnapshot<SharedPreferences> snapshot) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_expanded == -1) {
            _expanded = index;
          } else {
            _expanded = -1;
          }
          //_controller.reverse();

          if (_controller.isCompleted) {
            _controller.reverse();
          } else {
            _controller.forward();
          }
        });

        widget.analytics.logEvent(
            name: "user_card_clicked",
            parameters: {"expanded": _expanded == index ? true : false});
      },
      onLongPress: () {
        deleteCard(index);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: _expanded != index ? 230 : 500,
        width: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.transparent,
          border: Border.all(color: Colors.redAccent, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0),
              spreadRadius: 2,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
                top: 15,
                left: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color.fromRGBO(40, 40, 40, 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          "assets/logo_white.png",
                          width: 30,
                          color: Colors.redAccent.withOpacity(1),
                        ),
                      ),
                    ),
                  ],
                )),
            Positioned(
              child: Text(
                snapshot.data!.getStringList("wallet")![index],
                style:
                    TextStyle(color: Colors.white.withOpacity(0), fontSize: 10),
                textAlign: TextAlign.end,
              ),
              bottom: 5,
              right: 30,
            ),
            Positioned(
              child: Container(
                width: 200,
                child: AutoSizeText(
                  snapshot.data!.getStringList("wallet")![index].split("-")[0],
                  maxLines: 1,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color: Colors.white.withOpacity(1),
                      fontWeight: FontWeight.bold,
                      fontSize: 25),
                ),
              ),
              bottom: 5,
              right: 20,
            ),
            Center(
              child: QrImage(
                size: _expanded != index ? 150 : animation.value,
                data: snapshot.data!.getStringList("wallet")![index],
                foregroundColor: Colors.white,
                version: QrVersions.auto,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> checkPending() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey("requests")) {
      List<String>? saved = prefs.getStringList("requests");

      saved!.toSet().toList();

      for (String name in saved) {
        print(name.split(",")[1]);

        FirebaseFirestore.instance
            .collection('accepted')
            .doc(name.split(",")[0])
            .get()
            .then((DocumentSnapshot documentSnapshot) async {
          try {
            print(name.split(",")[1]);
            if (prefs.containsKey("wallet")) {
              List<String>? wallet = prefs.getStringList("wallet");
              wallet!.add(documentSnapshot.get(name.split(",")[1]));
              prefs.setStringList("wallet", wallet);
              setState(() {});

              await FirebaseFirestore.instance
                  .collection('accepted')
                  .doc(name.split(",")[0])
                  .set({name.split(",")[1]: FieldValue.delete()});
            } else {
              prefs.setStringList("wallet", []);
            }
          } catch (e) {}
        });
      }
      prefs.setStringList("requests", []);
    } else {
      prefs.setStringList("requests", []);
    }

    _refreshController.refreshCompleted();
  }

  Future<SharedPreferences> pref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
          //resizeToAvoidBottomInset: false,

          body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverPersistentHeader(
              pinned: true,
              floating: true,
              delegate: MyDynamicHeader(button()),
            ),
          ];
        },
        body: SmartRefresher(
            controller: _refreshController,
            onRefresh: checkPending,
            header: WaterDropHeader(),
            child: savedInvitese()),
      )),
    );
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

    _controller = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    animation = Tween<double>(begin: 150, end: 250).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    //controller!.dispose();
    super.dispose();
  }
}
