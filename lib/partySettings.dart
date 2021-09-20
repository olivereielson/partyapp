import 'package:bouncer/numberselect.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:page_transition/page_transition.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';

import 'login.dart';

class party_settings extends StatefulWidget {
  final FirebaseAnalytics analytics;
  String partyName;
  String partyCode;
  int reuse;

  party_settings(this.analytics,{required this.partyName,required this.partyCode,required this.reuse});



  @override
  State<party_settings> createState() => _party_settingsState();
}

class _party_settingsState extends State<party_settings> {

  bool _reusedCodes=false;



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


                FirebaseFirestore.instance.collection('party').doc(widget.partyName)
                    .delete().then((value){


                  Navigator.push(context, PageTransition(type: PageTransitionType.fade, child: LoginPage(analytics: widget.analytics,)));

                });






              }),
        ],
      ),
    );

  }

  void erase_confermation(){

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

                FirebaseFirestore.instance.collection('party')
                    .doc(widget.partyName)
                    .set({
                  'name': widget.partyName,
                  'password': widget.partyCode,
                  "invites":0,
                  "scans":0,
                  "numscan":1,
                  "reuse":false

                })
                    .then((value){

                  Navigator.pop(context);


                })
                    .catchError((error) => print("Failed to add user: $error"));



              }),
        ],
      ),
    );

  }

  Widget reuseWidhet(){


  return  Padding(
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

                FirebaseFirestore.instance.collection('party').doc(widget.partyName).set({"reuse": _reusedCodes},SetOptions(merge: true));


              })
        ],
      ),
    );

  }

  Future<void> _showPicker(BuildContext ctx) async {

    List<Text> t = [];


    for(int x=1; x<100; x++){

      t.add(Text("$x",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 30),));

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
                bottomRight: Radius.circular(40.0),
                topLeft: Radius.circular(40.0),
                bottomLeft: Radius.circular(40.0)),
          ),

          child: CupertinoPicker(
            backgroundColor: Colors.transparent,
            itemExtent: 50,
            scrollController: FixedExtentScrollController(initialItem:  widget.reuse-1 ),
            children: t,

            useMagnifier: true,

            selectionOverlay: Container(

              color: Color.fromRGBO(43, 43, 43, 0.2),

            ),
            onSelectedItemChanged: (value) {
              setState(() {
                widget.reuse = value;
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
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 30,
                                ),
                                onPressed: () {
                                  Navigator.pop(context, widget.reuse );
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
                 // String test= await Navigator.push(context, PageTransition(type: PageTransitionType.fade, child: NumberSelecter(analytics: widget.analytics,reuse: _reuse,)));

                  await _showPicker(context);

                  FirebaseFirestore.instance.collection('party').doc(widget.partyName).set({"numscan":  widget.reuse },SetOptions(merge: true));

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
              padding: const EdgeInsets.fromLTRB(20,30,20,30),
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

            Spacer(),

            Container(
              height: 300,
              child: ClipPath(
                clipper: ProsteThirdOrderBezierCurve(
                  position: ClipPosition.top,
                  list: [
                    ThirdOrderBezierCurveSection(
                      p1: Offset(0, 100),
                      p2: Offset(150, 300),
                      p3: Offset(200, 100),
                      p4: Offset(0, 200),
                    ),
                  ],
                ),
                child: Container(
                  height: 300,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.redAccent,

                  child: SafeArea(child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Text("Credits",style: TextStyle(fontSize: 15,color: Colors.white),),
                      ),
                    ],
                  )),

                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
