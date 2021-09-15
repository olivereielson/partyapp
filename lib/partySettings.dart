import 'package:bouncer/numberselect.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:page_transition/page_transition.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';

import 'login.dart';

class party_settings extends StatefulWidget {
  final FirebaseAnalytics analytics;

  party_settings(this.analytics);



  @override
  State<party_settings> createState() => _party_settingsState();
}

class _party_settingsState extends State<party_settings> {

  bool _reusedCodes=false;
  int reuse=1;



  void delete_confermation(){

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Party?"),
        content: Text("Are you sure you want to end the party? This action can not be undone."),
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

                Navigator.push(context, PageTransition(type: PageTransitionType.fade, child: LoginPage(analytics: widget.analytics,)));


              }),
        ],
      ),
    );

  }

  void erase_confermation(){

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Party?"),
        content: Text("Are you sure you want to end the party? This action can not be undone."),
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

                Navigator.push(context, PageTransition(type: PageTransitionType.fade, child: LoginPage(analytics: widget.analytics,)));


              }),
        ],
      ),
    );

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: 200,
              child: ClipPath(
                clipper: ProsteThirdOrderBezierCurve(
                  position: ClipPosition.bottom,
                  list: [
                    ThirdOrderBezierCurveSection(
                      p1: Offset(0, 100),
                      p2: Offset(10, 250),
                      p3: Offset(MediaQuery.of(context).size.width * 0.7, 100),
                      p4: Offset(MediaQuery.of(context).size.width, 140),
                    ),
                  ],
                ),
                child: Container(
                  height: 250,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.redAccent,
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
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 30,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20,0,20,0),
              child: GestureDetector(
                onTap: () async {
                  String test= await Navigator.push(context, PageTransition(type: PageTransitionType.fade, child: NumberSelecter(analytics: widget.analytics,reuse: reuse,)));

                  setState(() {
                    reuse=int.parse(test);
                  });

                  },
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.all(Radius.circular(15.0))),
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
                            "$reuse",
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
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
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
                          _reusedCodes=val;

                        });

                      })
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20,0,20,30),
              child: GestureDetector(
                onTap: (){                    erase_confermation();
                },
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.all(Radius.circular(15.0))),
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
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              child: GestureDetector(
                onTap: (){                    delete_confermation();
                },
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.all(Radius.circular(15.0))),
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


          ],
        ),
      ),
    );
  }
}
