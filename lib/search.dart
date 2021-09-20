
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';

class partySearch extends StatefulWidget{


  @override
  State<partySearch> createState() => _partySearchState();
}

class _partySearchState extends State<partySearch> {

  String _partyName="";


  @override
  Widget build(BuildContext context) {

    return SafeArea(
      bottom: false,
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: GestureDetector(
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
                            p1: Offset(0, 100),
                            p2: Offset(150, 400),
                            p3: Offset(200, 100),
                            p4: Offset(0, 400),
                          ),
                        ],
                      ),
                      child: Container(
                        height: 400,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.transparent,
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
                                "Search For Party",
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
                                    Icons.qr_code_scanner_outlined,
                                    size: 30,
                                    color: Colors.white,
                                  ))
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 70),
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
                        Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 80),
                          child: CupertinoButton(
                              color: Colors.redAccent,
                              child: Text(
                                "Search",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              onPressed: () async {
                              }),
                        ),
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
}