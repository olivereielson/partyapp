import 'package:bouncer/createparty.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import 'main.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final fb = FirebaseDatabase.instance;
  String _partyName = "";
  String _partyCode = "";


  SnackBar warning(String warning){


    return SnackBar(
      content: Text(warning,style: TextStyle(color: Colors.white),),
      backgroundColor: Colors.redAccent,
      action: SnackBarAction(
        label: '',
        textColor: Colors.white,
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    final ref = fb.reference();

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            Container(
              height: MediaQuery.of(context).size.height - 80,
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      child: Row(
                        children: [
                          Text(
                            "Host Party",
                            style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: TextField(
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(25)),
                            borderSide: BorderSide(color: Colors.redAccent, width: 2.0, style: BorderStyle.solid),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(25)),
                            borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
                          ),
                          hintText: 'Party Name',
                        ),
                        toolbarOptions: ToolbarOptions(),
                        onChanged: (String name) {
                          _partyName = name;
                        },
                        onSubmitted: (String name) {
                          _partyName = name;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: TextField(
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(25)),
                            borderSide: BorderSide(color: Colors.redAccent, width: 2.0, style: BorderStyle.solid),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(25)),
                            borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
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
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: CupertinoButton(
                          color: Colors.redAccent,
                          child: Text(
                            "Host Party",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {

                            if(_partyCode!=""&&_partyName!=""){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MyHomePage(
                                      partyCode: _partyCode,
                                      ref: ref,
                                      partyName: _partyName,
                                    )),
                              );
                            }else{

                              if(_partyName==""||_partyCode==""){
                                ScaffoldMessenger.of(context).showSnackBar(warning("Enter Party Name and Code"));
                              }



                            }



                            /*
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MyHomePage(partyCode: 'TestCode1234',ref: ref,)),
                        );

                         */
                          }),
                    ),
                    Spacer(),
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CreateParty(ref)),
                          );
                        },
                        child: Text(
                          "Create Party",
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ))
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
