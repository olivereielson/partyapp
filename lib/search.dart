
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class partySearch extends StatefulWidget{


  @override
  State<partySearch> createState() => _partySearchState();
}

class _partySearchState extends State<partySearch> {

  String _partyName="";
  String _Name="";
  TextEditingController _nameController=TextEditingController();
  TextEditingController _partyNameController=TextEditingController();


  warning(String warning) {
    showTopSnackBar(
      context,
      CustomSnackBar.error(
        message: warning,
      ),
    );

  }
  success(String message) {
    showTopSnackBar(
      context,
      CustomSnackBar.success(
        message: message,
      ),
      displayDuration: Duration(milliseconds: 500)
    );
  }

  Future<void> saveName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if(prefs.containsKey("requests")){


     List<String>? saved=  prefs.getStringList("requests");
     saved!.add(_partyName+","+_Name);
     print(saved);
     prefs.setStringList("requests", saved);

    }else{
      prefs.setStringList("requests", []);
    }


  }

  Future<bool> canRequest() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    if(prefs.containsKey("requests")){

      List<String>? saved=  prefs.getStringList("requests");

      if(saved!.contains(_partyName+","+_Name)){

        warning("You Have Already Sent a Request");

        return false;


      }

    }else{

      prefs.setStringList("requests", []);

    }


    return true;


  }

  Future<void> request() async {



    if(await canRequest()) {
      var collectionRef = FirebaseFirestore.instance.collection('party');
      var doc = await collectionRef.doc(_partyName).get();

      if (doc.exists) {

        _Name=_Name.toTitleCase();

        FirebaseFirestore.instance.collection('requests').doc(_partyName).set(
            {_Name: "0"}, SetOptions(merge: true));
        success("Request Sent");
        saveName();
        _partyNameController.clear();
        _nameController.clear();

      } else {
        warning("Invalid Party Name");
      }
    }


  }



  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                child: Container(
                  height: 500,
                  child: ClipPath(
                    clipper: ProsteThirdOrderBezierCurve(
                      position: ClipPosition.bottom,
                      list: [
                        ThirdOrderBezierCurveSection(
                          p1: Offset(0, 100),
                          p2: Offset(5, 200),
                          p3: Offset(400, 50),
                          p4: Offset(800, 300),
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

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 20),
                          child: Row(
                            children: [
                              Text(
                                "Request Invite",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold),
                              ),
                              Spacer(),
                            ],
                          ),
                        ),



                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 50),
                          child: TextField(
                            cursorColor: Colors.redAccent,
                            controller: _nameController,
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
                                hintText: 'Name',
                                ),
                            toolbarOptions: ToolbarOptions(),
                            onChanged: (String name) {
                              setState(() {
                                _Name = name;
                              });
                            },
                            onSubmitted: (String name) {
                              _Name = name;

                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 0),
                          child: TextField(
                            cursorColor: Colors.redAccent,
                            controller: _partyNameController,
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

                            },
                            maxLength: 20,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 0,top: 50),
                          child: CupertinoButton(
                              color: Colors.redAccent,
                              child: Text(
                                "Send Request",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              onPressed: () async {


                                if(_partyName.replaceAll(" ", "")==""){
                                  warning("Enter Party Name");
                                }
                                if(_Name.replaceAll(" ", "")==""){
                                  warning("Enter Your Name");
                                }

                                if(_partyName.replaceAll(" ", "")!=""&&_Name.replaceAll(" ", "")!=""){

                                  request();

                                }

                              }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );



  }
}
extension StringCasingExtension on String {
  String toCapitalized() => this.length > 0 ?'${this[0].toUpperCase()}${this.substring(1)}':'';
  String toTitleCase() => this.replaceAll(RegExp(' +'), ' ').split(" ").map((str) => str.toCapitalized()).join(" ");
}