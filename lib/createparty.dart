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
                            children: [
                              Text(
                                "Create Party",
                                style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                              ),
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
                            onSubmitted: (String code) {},
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
                            onSubmitted: (String code) {},
                          ),
                        ),
                        Spacer(),
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
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MyHomePage(
                                            partyCode: 'TestCode1234',
                                            ref: widget.ref,
                                          )),
                                );
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
