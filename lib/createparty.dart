import 'dart:convert';

import 'package:bouncer/partyStructure.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'main.dart';

class CreateParty extends StatefulWidget {
  DatabaseReference ref;

  CreateParty(this.ref);

  @override
  _CreatePartyState createState() => _CreatePartyState();
}

class _CreatePartyState extends State<CreateParty> {
  bool _reuse = false;
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

  Future<bool> loginfo(ref) async {
    DataSnapshot snapshot = await ref.child(_partyName).once();

    if (!snapshot.exists) {
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(warning("Name Already Exists"));

    return false;
  }



  @override
  Widget build(BuildContext context) {
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
                  child: Padding(
                    padding: const EdgeInsets.only(top: 90),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Create Party",
                                style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
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
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                          child: TextField(
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.redAccent, width: 2.0, style: BorderStyle.solid),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                          child: TextField(
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.redAccent, width: 2.0, style: BorderStyle.solid),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
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
                            padding: const EdgeInsets.symmetric(vertical: 100),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Colors.red,
                                onPrimary: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                elevation: 0,
                                minimumSize: Size((MediaQuery.of(context).size.width - 70), 60),
                              ),
                              child: Text(
                                "Create Party",
                                style: TextStyle(fontSize: 15),
                              ),
                              onPressed: () async {

                                if(_partyCode!=""&&_partyName!=""){
                                  bool test = await loginfo(widget.ref);
                                  if(test){

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => MyHomePage(
                                            partyCode: _partyCode,
                                            partyName: _partyName,
                                            ref: widget.ref,
                                          )),
                                    );
                                  }



                                }else{

                                  if(_partyName==""||_partyCode==""){
                                    ScaffoldMessenger.of(context).showSnackBar(warning("Enter Party Name and Code"));
                                  }



                                }
                              },
                            ))
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
