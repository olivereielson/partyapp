
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

  Future<void> request() async {

    var collectionRef = FirebaseFirestore.instance.collection('party');
    var doc = await collectionRef.doc(_partyName).get();

    if(doc.exists){


      FirebaseFirestore.instance.collection('requests').doc(_partyName).set({_Name: "0"},SetOptions(merge: true));
      success("Request Sent");
      saveName();
      setState(() {
      //  _partyName="";
        //_Name="";
      });

    }else{
      warning("Invalid Party Name");
    }



  }



  @override
  Widget build(BuildContext context) {

    return SafeArea(
      bottom: false,
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
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
        ),
      ),
    );



  }
}