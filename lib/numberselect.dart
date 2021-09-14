import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'dart:math' as math;

class NumberSelecter extends StatefulWidget {
  final FirebaseAnalytics analytics;
  int reuse;

  NumberSelecter({required this.analytics,required this.reuse});

  @override
  State<NumberSelecter> createState() => _NumberSelecterState();
}

class _NumberSelecterState extends State<NumberSelecter> {

  String numbers="0";


  void infoButton() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Party Scans"),
        content: Text(
            "This changes the amount of time a QR code can be scanned before it ges regected.  For example you could give a code with 10 scans to a group of ten friends. After all 10 friends scan in the code no longer works."),
        actions: <Widget>[
          CupertinoButton(
              child: Text(
                "Ok",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.pop(context);
              }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              infoButton();
            },
          )
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 130),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.redAccent,
                              width: 2.0,
                              style: BorderStyle.solid),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.redAccent, width: 2.0),
                        ),
                        hintText: '${widget.reuse} Scan Per Invite',
                      ),
                      toolbarOptions: ToolbarOptions(),
                      textInputAction: TextInputAction.done,

                      onChanged: (String code) {

                        numbers=code;


                      },
                      onSubmitted: (String code) {

                        Navigator.pop(context,code);


                      },
                      cursorColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
