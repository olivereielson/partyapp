
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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


    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {


      warning("No Internet Connection");

    }

    if(connectivityResult != ConnectivityResult.none) {
      if (prefs.containsKey("requests")) {
        List<String>? saved = prefs.getStringList("requests");

        if (saved!.contains(_partyName + "," + _Name)) {
          warning("You Have Already Sent a Request");

          return false;
        }
      } else {
        prefs.setStringList("requests", []);
      }
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
          child: Padding(
            padding: const EdgeInsets.only(top: 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [

                Container(
                  child: Stack(
                    children: [
                      Container(

                        child: ClipPath(
                          clipper: ProsteThirdOrderBezierCurve(
                            position: ClipPosition.bottom,
                            list: [
                              ThirdOrderBezierCurveSection(
                                p1: Offset(0, 100),
                                p2: Offset(5, 170),
                                p3: Offset(400, 80),
                                p4: Offset(MediaQuery.of(context).size.width, 150),
                              ),
                            ],
                          ),
                          child: Container(
                            height: 170,
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
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Container(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 10),
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
                                IconButton(onPressed: (){



                                }, icon: Icon(Icons.info_outline))
                              ],
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),


                Padding(
                  padding: const EdgeInsets.fromLTRB(30,0,30,50),
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
    );



  }
}
extension StringCasingExtension on String {
  String toCapitalized() => this.length > 0 ?'${this[0].toUpperCase()}${this.substring(1)}':'';
  String toTitleCase() => this.replaceAll(RegExp(' +'), ' ').split(" ").map((str) => str.toCapitalized()).join(" ");
}