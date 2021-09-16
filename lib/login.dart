import 'dart:convert';

import 'package:bouncer/User.dart';
import 'package:bouncer/createparty.dart';
import 'package:bouncer/partyStructure.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:page_transition/page_transition.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';

import 'main.dart';

class LoginPage extends StatefulWidget {
  LoginPage({required this.analytics});

  final FirebaseAnalytics analytics;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _partyName = "";
  String _partyCode = "";

  SnackBar warning(String warning) {
    return SnackBar(
      content: Text(
        warning,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Color.fromRGBO(43, 43, 43, 1),
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    );
  }

  Future<bool> loginfo(ref) async {
    DataSnapshot snapshot = await ref.child(_partyName).once();

    if (!snapshot.exists) {
      print("name does not exist");
      ScaffoldMessenger.of(context)
          .showSnackBar(warning("Party Name Does not exist"));

      return true;
    }
    String p = json.decode(snapshot.value)["partyCode"].toString();

    print(_partyCode);
    print(p);

    if (p != _partyCode) {
      ScaffoldMessenger.of(context).showSnackBar(warning("Wrong Party Code"));

      print("code does not exist");

      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    CollectionReference parties =
        FirebaseFirestore.instance.collection('party');

    return WillPopScope(
      onWillPop: () async => false,
      child: PageView(
        scrollDirection: Axis.horizontal,
        allowImplicitScrolling: false,
        padEnds: false,
        physics: ClampingScrollPhysics(),
        pageSnapping: true,
        dragStartBehavior: DragStartBehavior.down,
        children: [
          Userpage(
            analytics: widget.analytics,
          ),
          Scaffold(
              resizeToAvoidBottomInset:false,
            body: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: ListView(
                physics: NeverScrollableScrollPhysics(),
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height,
                    child: Stack(
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
                              height: 400,
                              width: MediaQuery.of(context).size.width,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 20),
                                child: Row(
                                  children: [
                                    Text(
                                      "Host Party",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(30.0),
                                child: TextField(
                                  cursorColor: Colors.redAccent,
                                  decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(25)),
                                      borderSide: BorderSide(
                                          color: Colors.redAccent,
                                          width: 2.0,
                                          style: BorderStyle.solid),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(25)),
                                      borderSide: BorderSide(
                                          color: Colors.redAccent, width: 2.0),
                                    ),
                                    hintText: 'Party Name',
                                  ),
                                  toolbarOptions: ToolbarOptions(),
                                  onChanged: (String name) {
                                    _partyName = name;
                                  },
                                  onSubmitted: (String name) {
                                    _partyName = name;
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(30.0),
                                child: TextField(
                                  decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(25)),
                                      borderSide: BorderSide(
                                          color: Colors.redAccent,
                                          width: 2.0,
                                          style: BorderStyle.solid),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(25)),
                                      borderSide: BorderSide(
                                          color: Colors.redAccent, width: 2.0),
                                    ),
                                    hintText: 'Party Code',
                                  ),
                                  toolbarOptions: ToolbarOptions(),
                                  onChanged: (String code) {
                                    _partyCode = code;
                                  },
                                  onSubmitted: (String code) {
                                    _partyCode = code;
                                  },
                                  cursorColor: Colors.redAccent,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 80),
                                child: CupertinoButton(
                                    color: Colors.redAccent,
                                    child: Text(
                                      "Host Party",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () async {
                                      if (_partyCode != "" &&
                                          _partyName != "") {
                                        FirebaseFirestore.instance
                                            .collection('party')
                                            .doc(_partyName)
                                            .get()
                                            .then((DocumentSnapshot
                                                documentSnapshot) {
                                          if (documentSnapshot.exists) {
                                            if (documentSnapshot
                                                    .get("password") ==
                                                _partyCode) {
                                              widget.analytics.logEvent(
                                                name: "party_logg_in",
                                                parameters: <String, dynamic>{
                                                  'success ': true,
                                                },
                                              );
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        MyHomePage(
                                                          partyCode: _partyCode,
                                                          partyName: _partyName,
                                                          analytics:
                                                              widget.analytics,
                                                        )),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(warning(
                                                      "Wrong Party Code"));
                                            }

                                            widget.analytics.logEvent(
                                              name: "party_logg_in",
                                              parameters: <String, dynamic>{
                                                'success ': false,
                                              },
                                            );
                                          } else {
                                            widget.analytics.logEvent(
                                              name: "party_logg_in",
                                              parameters: <String, dynamic>{
                                                'success ': false,
                                              },
                                            );

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(warning(
                                                    "Wrong Party Name"));
                                          }
                                        });
                                      }
                                    }),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).size.height - 120,
                          left: (MediaQuery.of(context).size.width - 200) / 2,
                          child: Container(
                            width: 200,
                            color: Colors.transparent,
                            child: Center(
                              child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        PageTransition(
                                            type:
                                                PageTransitionType.bottomToTop,
                                            duration:
                                                Duration(milliseconds: 500),
                                            child: CreateParty(
                                              analytics: widget.analytics,
                                            )));
                                  },
                                  child: Text(
                                    "Create Party",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  )),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  Future<void> _testSetCurrentScreen() async {
    await widget.analytics.setCurrentScreen(
      screenName: 'LogIn Page',
      screenClassOverride: 'LoginPage',
    );
  }

  @override
  void initState() {
    _testSetCurrentScreen();
    super.initState();
  }
}
