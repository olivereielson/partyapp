import 'dart:convert';

import 'package:bouncer/partyStructure.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'main.dart';

class CreateParty extends StatefulWidget {
  final FirebaseAnalytics analytics;

  CreateParty({required this.analytics});

  @override
  _CreatePartyState createState() => _CreatePartyState();
}

class _CreatePartyState extends State<CreateParty> {
  bool _reuse = false;
  String _partyName = "";
  String _partyCode = "";
  FirebasePerformance _performance = FirebasePerformance.instance;

  Future<void> _testSetCurrentScreen() async {
    await widget.analytics.setCurrentScreen(
      screenName: 'Create Party Page',
      screenClassOverride: 'CreatePartyPage',
    );
  }

  @override
  Widget build(BuildContext context) {
    CollectionReference parties =
        FirebaseFirestore.instance.collection('party');

    Future<void> addParty() async {
      final Trace trace = _performance.newTrace('create_party');
      await trace.start();

      return parties
          .doc(_partyName)
          .set({
            'name': _partyName,
            'password': _partyCode,
            "invites": 0,
            "scans": 0,
            "numscan": 1,
            "reuse": false
          })
          .then((value) async {

        await trace.stop();


      }).catchError((error) => print("Failed to add user: $error"));
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: ListView(
            physics: NeverScrollableScrollPhysics(),
            children: [
              Container(
                height: MediaQuery.of(context).size.height,
                child: SafeArea(
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 0,
                        child: ClipPath(
                          clipper: ProsteThirdOrderBezierCurve(
                            position: ClipPosition.top,
                            list: [
                              ThirdOrderBezierCurveSection(
                                p1: Offset(0, 500),
                                p2: Offset(150, 400),
                                p3: Offset(70, 650),
                                p4: Offset(0, 500),
                              ),
                            ],
                          ),
                          child: Container(
                            height: 700,
                            width: MediaQuery.of(context).size.width,
                            color: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 30),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Create Party",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      icon: Icon(
                                        Icons.close,
                                        size: 30,
                                      ))
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(30, 50, 30, 20),
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
                                maxLength: 20,
                                toolbarOptions: ToolbarOptions(),
                                onChanged: (String name) {
                                  setState(() {
                                    _partyName = name;
                                  });
                                },
                                onSubmitted: (String name) {
                                  _partyName = name;
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 0),
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
                                  hintText: 'Party Code',
                                ),
                                toolbarOptions: ToolbarOptions(),
                                onChanged: (String code) {
                                  _partyCode = code;
                                },
                                onSubmitted: (String code) {
                                  _partyCode = _partyCode;
                                },
                              ),
                            ),
                            Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 100, horizontal: 80),
                                child: CupertinoButton(
                                    color: Colors.redAccent,
                                    child: Text(
                                      "Create Party",
                                      style: TextStyle(
                                          fontSize: 15, color: Colors.white),
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


                                      if (_partyName.replaceAll(" ", "") ==
                                              "" ||
                                          _partyCode.replaceAll(" ", "") ==
                                              "") {
                                        showTopSnackBar(
                                          context,
                                          CustomSnackBar.error(
                                            message: _partyName.replaceAll(
                                                        " ", "") ==
                                                    ""
                                                ? "Create A Party Name"
                                                : "Create A Party Code",
                                          ),
                                        );

                                        widget.analytics.logEvent(
                                            name: "party_created",
                                            parameters: {"sucsess": false});
                                      } else {
                                        FirebaseFirestore.instance
                                            .collection('party')
                                            .doc(_partyName)
                                            .get()
                                            .then((DocumentSnapshot
                                                documentSnapshot) {
                                          if (documentSnapshot.exists) {
                                            showTopSnackBar(
                                              context,
                                              CustomSnackBar.error(
                                                message:
                                                    "Party Name Already Used",
                                              ),
                                            );
                                          } else {
                                            addParty();

                                            widget.analytics.logEvent(
                                                name: "party_created",
                                                parameters: {"sucsess": true});

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
                                          }
                                        });
                                      }
                                    }})),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    _testSetCurrentScreen();
    super.initState();
  }
}
