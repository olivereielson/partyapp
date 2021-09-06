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
              height: MediaQuery.of(context).size.height,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
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
                        toolbarOptions: ToolbarOptions(

                        ),




                        onSubmitted: (String code) {

                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MyHomePage(partyCode: code,ref: ref,)),
                          );
                        },
                      ),
                    ),
                    CupertinoButton(color: Colors.redAccent, child: Text("Create Party"), onPressed: () {


                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyHomePage(partyCode: 'TestCode1234',ref: ref,)),
                      );

                    })
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
