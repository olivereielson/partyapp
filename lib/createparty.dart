import 'dart:convert';

import 'package:bouncer/partyStructure.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class CreateParty extends StatefulWidget {
  final FirebaseAnalytics analytics;

  CreateParty( {required this.analytics});

  @override
  _CreatePartyState createState() => _CreatePartyState();
}

class _CreatePartyState extends State<CreateParty> {
  bool _reuse = false;
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
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(warning("Name Already Exists"));

    return false;
  }

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


    Future<void> addParty() {
      return parties
          .doc(_partyName)
          .set({
        'name': _partyName,
        'password': _partyCode,
        "invites":0,
        "scans":0,
        "numscan":1,
        "reuse":false

      })
          .then((value) => print("User Added"))
          .catchError((error) => print("Failed to add user: $error"));
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
                            height: 650,
                            width: MediaQuery.of(context).size.width,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 90),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 50),
                              child: TextField(
                                cursorColor: Colors.redAccent,
                                decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(
                                        color: Colors.redAccent,
                                        width: 2.0,
                                        style: BorderStyle.solid),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(
                                        color: Colors.redAccent, width: 2.0),
                                  ),
                                  hintText: 'Party Name',

                                  counter: Text("${_partyName.length}/20")

                                ),
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
                                  horizontal: 30, vertical: 10),
                              child: TextField(
                                cursorColor: Colors.redAccent,
                                decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(
                                        color: Colors.redAccent,
                                        width: 2.0,
                                        style: BorderStyle.solid),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide(
                                        color: Colors.redAccent, width: 2.0),
                                  ),
                                  hintText: 'Party Password',
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 100),
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.redAccent,
                                      onPrimary: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      elevation: 0,
                                      minimumSize: Size(
                                          (MediaQuery.of(context).size.width -
                                              70),
                                          60),
                                    ),
                                    child: Text(
                                      "Create Party",
                                      style: TextStyle(fontSize: 15),
                                    ),
                                    onPressed: () async {
                                      
                                      
                                      FirebaseFirestore.instance
                                          .collection('party')
                                          .doc(_partyName)
                                          .get()
                                          .then((DocumentSnapshot
                                              documentSnapshot) {
                                        if (documentSnapshot.exists) {

                                          ScaffoldMessenger.of(context).showSnackBar(warning("Party Name Already Used"));


                                        } else {

                                          addParty();

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => MyHomePage(
                                                  partyCode: _partyCode,
                                                  partyName: _partyName,
                                                  analytics: widget.analytics,
                                                )),
                                          );

                                        }
                                      });

                                      /*

                                    if (_partyCode != "" && _partyName != "") {
                                      bool test = await loginfo(widget.ref);
                                      if (test) {
                                        widget.analytics.logEvent(
                                          name: "party_created",
                                          parameters: <String, dynamic>{
                                            'success ': true,
                                          },
                                        );

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => MyHomePage(
                                                    partyCode: _partyCode,
                                                    partyName: _partyName,
                                                    ref: widget.ref,
                                                    analytics: widget.analytics,
                                                  )),
                                        );
                                      }
                                    } else {
                                      if (_partyName == "" || _partyCode == "") {
                                        ScaffoldMessenger.of(context).showSnackBar(warning("Enter Party Name and Code"));
                                        widget.analytics.logEvent(
                                          name: "party_created",
                                          parameters: <String, dynamic>{
                                            'success ': false,
                                          },
                                        );
                                      }
                                    }

                                     */
                                    })),
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
