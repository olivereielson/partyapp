import 'package:bouncer/createparty.dart';
import 'package:bouncer/numberselect.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:page_transition/page_transition.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import 'login.dart';

class party_settings extends StatefulWidget {
  final FirebaseAnalytics analytics;
  String partyName;
  String partyCode;
  int reuse;

  party_settings(this.analytics,
      {required this.partyName, required this.partyCode, required this.reuse});

  @override
  State<party_settings> createState() => _party_settingsState();
}

class _party_settingsState extends State<party_settings> {
  bool _reusedCodes = false;


  warning(String warning) {
    showTopSnackBar(
      context,
      CustomSnackBar.error(
        message: warning,
      ),
    );

  }

  Future<bool> delete_confermation() async {
    bool test = await showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text("Delete Party?"),
        content: Text(
            "Are you sure you want to end the party? This action can not be undone."),
        actions: <Widget>[
          CupertinoButton(
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.pop(context, false);
              }),
          CupertinoButton(
              child: Text(
                "Delete",
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () async {

                Navigator.pop(context, true);




                //Navigator.of(context).popUntil(ModalRoute.withName('/my-target-screen'));

                //
              }),
        ],
      ),
    );

    return test;
  }

  void erase_confermation() {
    showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text("Reset Party"),
        content: Text("Are you sure you want to reset the party?"),
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
                "Reset",
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () async {
                FirebaseFirestore.instance
                    .collection('party')
                    .doc(widget.partyName)
                    .set({
                  'name': widget.partyName,
                  'password': widget.partyCode,
                  "invites": 0,
                  "scans": 0,
                  "numscan": 1,
                  "reuse": false
                }).then((value) {
                  Navigator.pop(context);
                }).catchError((error) => print("Failed to add user: $error"));
              }),
        ],
      ),
    );
  }


  Widget reuseWidhet() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.all(Radius.circular(15.0))),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.restart_alt,
                size: 40,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Allow Reused Codes",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Spacer(),
          CupertinoSwitch(
              activeColor: Colors.redAccent,
              value: _reusedCodes,
              onChanged: (val) {
                setState(() {
                  _reusedCodes = val;
                });

                FirebaseFirestore.instance
                    .collection('party')
                    .doc(widget.partyName)
                    .set({"reuse": _reusedCodes}, SetOptions(merge: true));
              })
        ],
      ),
    );
  }

  Future<void> _showPicker(BuildContext ctx) async {
    List<Text> t = [];

    for (int x = 1; x < 100; x++) {
      t.add(Text(
        "$x",
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30),
      ));
    }

    await showCupertinoModalPopup(
        context: ctx,
        builder: (_) => Container(
              width: MediaQuery.of(context).size.width,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(40.0),
                    bottomRight: Radius.circular(0),
                    topLeft: Radius.circular(40.0),
                    bottomLeft: Radius.circular(0)),
              ),
              child: CupertinoPicker(
                backgroundColor: Colors.transparent,
                itemExtent: 50,
                scrollController:
                    FixedExtentScrollController(initialItem: widget.reuse - 1),
                children: t,
                looping: true,
                useMagnifier: true,
                selectionOverlay: Container(
                  color: Color.fromRGBO(43, 43, 43, 0.2),
                ),
                onSelectedItemChanged: (value) {
                  setState(() {
                    widget.reuse = value + 1;
                  });
                },
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              child: Container(
                height: 300,
                child: ClipPath(
                  clipper: ProsteThirdOrderBezierCurve(
                    position: ClipPosition.bottom,
                    list: [
                      ThirdOrderBezierCurveSection(
                        p1: Offset(0, 150),
                        p2: Offset(5, 230),
                        p3: Offset(400, 50),
                        p4: Offset(800, 400),
                      ),
                    ],
                  ),
                  child: Container(
                    height: 300,
                    width: MediaQuery.of(context).size.width,
                    // color: Colors.grey.withOpacity(0.1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          //CupertinoColors.systemPink,
                          Colors.pink,
                          Colors.red,
                        ],

                      ),
                      border: Border.all(
                          color: Colors.transparent, width: 3),
                    ),
                    child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Text(
                                "Credits",
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withOpacity(0)),
                              ),
                            ),
                          ],
                        )),
                  ),
                ),
              ),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  color: Colors.transparent,
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Party Settings",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 35,
                                    fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 30,
                                ),
                                onPressed: () {
                                  Navigator.pop(context, widget.reuse);
                                },
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                  child: GestureDetector(
                    onTap: () async {
                      // String test= await Navigator.push(context, PageTransition(type: PageTransitionType.fade, child: NumberSelecter(analytics: widget.analytics,reuse: _reuse,)));

                      await _showPicker(context);

                      FirebaseFirestore.instance.collection('party').doc(widget.partyName).set({"numscan": widget.reuse}, SetOptions(merge: true));

                      widget.analytics.logEvent(
                          name: "reuse_num_changed",
                          parameters: {"num": widget.reuse});
                    },
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15.0))),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.qr_code,
                              size: 40,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Scans Per Code",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${widget.reuse}",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right)
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                  child: GestureDetector(
                    onTap: () async {
                      var connectivityResult = await (Connectivity().checkConnectivity());

                     if(connectivityResult != ConnectivityResult.none){
                       erase_confermation();
                       widget.analytics.logEvent(
                         name: "party_reset",
                       );
                     }else{

                       warning("No Internet Connection");

                     }

                    },
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15.0))),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.restart_alt_outlined,
                              size: 40,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Reset Invite List",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right)
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  child: GestureDetector(
                    onTap: () async {

                      var connectivityResult = await (Connectivity().checkConnectivity());

                      if(connectivityResult != ConnectivityResult.none){

                        bool test = await delete_confermation();

                        if (test) {
                          Navigator.pop(context,-1);
                        }

                        widget.analytics.logEvent(
                            name: "party_delete_clicked",
                            parameters: {"deleted": test});

                      }else{

                        warning("No Internet Connection");

                      }


                    },
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15.0))),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.delete,
                              size: 40,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Delete Party",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right)
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  child: GestureDetector(
                    onTap: () {
                      widget.analytics.logEvent(
                        name: "party_logged_out",
                      );

                      pushNewScreen(
                        context,
                        screen: LoginPage(analytics: widget.analytics),
                        withNavBar: true,
                        pageTransitionAnimation:
                            PageTransitionAnimation.cupertino,
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15.0))),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.logout,
                              size: 40,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Log Out",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      screenName: 'Party Settings Page',
      screenClassOverride: 'Party_Settings_Page',
    );
  }
}
