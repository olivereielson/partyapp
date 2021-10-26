import 'dart:convert';
import 'package:bouncer/User.dart';
import 'package:bouncer/createparty.dart';
import 'package:bouncer/partyStructure.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:page_transition/page_transition.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
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
  PageController pc = PageController(initialPage: 0);


  warning(String warning) {
    showTopSnackBar(
      context,
      CustomSnackBar.error(
        message: warning,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Container(
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
                            p1: Offset(0, 120),
                            p2: Offset(150, 400),
                            p3: Offset(200, 100),
                            p4: Offset(0, 400),
                          ),
                        ],
                      ),
                      child: Container(
                        height: 400,
                        width: MediaQuery.of(context).size.width,
                        //color: Colors.redAccent,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(0),
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              //CupertinoColors.systemPink,
                              Colors.pink,
                              Colors.red,
                            ],

                          ),
                          border: Border.all(
                              color: Colors.transparent, width: 3),
                        ),
                        //color: Colors.grey.withOpacity(0.1),
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
                              Spacer(),
                              IconButton(
                                  onPressed: () {
                                    // Navigator.pop(context);
                                  },
                                  icon: Icon(
                                    Icons.close,
                                    size: 30,
                                    color: Colors.transparent,
                                  ))
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
                                counter: Text("${_partyName.length}/20")),
                            toolbarOptions: ToolbarOptions(),
                            onChanged: (String name) {
                              setState(() {
                                _partyName = name;
                              });
                            },
                            onSubmitted: (String name) {
                              _partyName = name;
                            },
                            maxLength: 20,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
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
                            style: TextStyle(decorationColor: Colors.yellow),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 50),
                          child: CupertinoButton(
                              color: Colors.redAccent,
                              child: Text(
                                "Host Party",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              onPressed: () async {


                                var connectivityResult = await (Connectivity().checkConnectivity());
                                if (connectivityResult == ConnectivityResult.none) {

                                  showTopSnackBar(
                                    context,
                                    CustomSnackBar.error(
                                      message: "No Internet Connection",
                                    ),
                                  );


                                }else{

                                if (_partyCode != "" && _partyName != "") {
                                  FirebaseFirestore.instance
                                      .collection('party')
                                      .doc(_partyName)
                                      .get()
                                      .then((DocumentSnapshot documentSnapshot) {
                                    if (documentSnapshot.exists) {
                                      if (documentSnapshot.get("password") ==
                                          _partyCode) {
                                        widget.analytics.logEvent(
                                          name: "party_logg_in",
                                          parameters: <String, dynamic>{
                                            'success': true,
                                          },
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => MyHomePage(
                                                    partyCode: _partyCode,
                                                    partyName: _partyName,
                                                    analytics: widget.analytics,
                                                  )),
                                        );
                                      } else {
                                        warning("Wrong Party Code");
                                      }

                                      widget.analytics.logEvent(
                                        name: "party_logg_in",
                                        parameters: <String, dynamic>{
                                          'success': false,
                                        },
                                      );
                                    } else {
                                      widget.analytics.logEvent(
                                        name: "party_logg_in",
                                        parameters: <String, dynamic>{
                                          'success': false,
                                        },
                                      );

                                      warning("Wrong Party Name");
                                    }
                                  });
                                }else{

                                  showTopSnackBar(
                                    context,
                                    CustomSnackBar.error(
                                      message: _partyName.replaceAll(" ", "")==""?"Enter A Party Name":"Enter A Party Code",
                                    ),
                                  );

                                }}
                              }),
                        ),
                        Spacer(),
                        TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  PageTransition(
                                      type: PageTransitionType.bottomToTop,
                                      duration: Duration(milliseconds: 500),
                                      child: CreateParty(
                                        analytics: widget.analytics,
                                      )));
                            },
                            child: Text(
                              "Create Party",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ))
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
