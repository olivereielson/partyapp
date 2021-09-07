import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CreateParty extends StatefulWidget {
  @override
  _CreatePartyState createState() => _CreatePartyState();
}

class _CreatePartyState extends State<CreateParty> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            child: Padding(
              padding: const EdgeInsets.only(top: 90),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        Text("Create Party",style: TextStyle(color: Colors.white,fontSize: 30,fontWeight: FontWeight.bold),),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 50),
                    child: TextField(
                      decoration: InputDecoration(

                        hintText: 'Create Party Code',
                        fillColor: Colors.red,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.redAccent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.redAccent),
                        ),
                      ),
                      toolbarOptions: ToolbarOptions(),
                      onSubmitted: (String code) {

                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
