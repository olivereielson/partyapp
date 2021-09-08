import 'package:bouncer/UserScan.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:proste_bezier_curve/proste_bezier_curve.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Userpage extends StatefulWidget {
  DatabaseReference ref;

  Userpage(this.ref);

  @override
  _UserpageState createState() => _UserpageState();
}

class _UserpageState extends State<Userpage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR2');
  Barcode? result;
  QRViewController? controller;

  Scaffold savedInvites() {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top:0,
            child: ClipPath(
              clipper: ProsteThirdOrderBezierCurve(
                position: ClipPosition.bottom,
                list: [
                  ThirdOrderBezierCurveSection(
                    p1: Offset(100, 100),
                    p2: Offset(50, 100),
                    p3: Offset(400, 150),
                    p4: Offset(300, 100),
                  ),
                ],
              ),

              child: Container(

                height: 200,
                width: MediaQuery.of(context).size.width,
                color: Colors.redAccent,


              ),
            ),
          ),

          SafeArea(
            bottom: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
                  child: Row(
                    children: [
                      Text(
                        "Saved Passes",
                        style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                    width: MediaQuery.of(context).size.width,
                    height: 250,
                    child: FutureBuilder(
                      future: pref(),
                      builder: (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
                        if (snapshot.hasData&& snapshot.data!.getStringList("wallet")!=null) {

                          if( snapshot.data!.getStringList("wallet")!.length==0){

                            return Padding(
                              padding: const EdgeInsets.all(30.0),
                              child: Container(
                                height: 100,
                                width: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.redAccent,
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                        child: Text("No Saved Cards",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),)
                                    ),
                                  ],
                                ),
                              ),
                            );

                          }



                          return Swiper(
                            itemBuilder: (BuildContext context, int index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: GestureDetector(
                                  onLongPress: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => CupertinoAlertDialog(
                                        title: Text("Delete Pass?"),
                                        content: Text("This action can not be undone"),
                                        actions: <Widget>[
                                          CupertinoButton(
                                              child: Text(
                                                "Cancel",
                                                style: TextStyle(color: Colors.white),
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);
                                              }),
                                          CupertinoButton(
                                              child: Text(
                                                "Delete",
                                                style: TextStyle(color: Colors.redAccent),
                                              ),
                                              onPressed: () async {
                                                SharedPreferences prefs = await SharedPreferences.getInstance();

                                                if (prefs.containsKey("wallet")) {
                                                  List<String>? codes = prefs.getStringList("wallet");
                                                  codes!.removeAt(index);
                                                  prefs.setStringList("wallet", codes);
                                                } else {
                                                  prefs.setStringList("wallet", []);
                                                }

                                                setState(() {});
                                                Navigator.pop(context);
                                              }),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 100,
                                    width: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.redAccent,
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          child: Text(
                                            "id:" + snapshot.data!.getStringList("wallet")![index],
                                            style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                          ),
                                          bottom: 5,
                                          right: 5,
                                        ),
                                        Center(
                                          child: QrImage(
                                            size: 200,
                                            data: snapshot.data!.getStringList("wallet")![index],
                                            foregroundColor: Colors.white,
                                            version: QrVersions.auto,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            itemCount: snapshot.data!.getStringList("wallet") != null ? snapshot.data!.getStringList("wallet")!.length : 0,
                            pagination: DotSwiperPaginationBuilder(color: Colors.transparent, activeColor: Colors.transparent),
                            loop: false,
                            control: SwiperControl(color: Colors.transparent, disableColor: Colors.transparent),
                          );
                        }

                        return                        Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Container(
                            height: 100,
                            width: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.redAccent,
                            ),
                            child: Stack(
                              children: [
                                Center(
                                    child: Text("No Saved Cards",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),)
                                ),
                              ],
                            ),
                          ),
                        );
                        ;
                      },
                    )),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 90),
                  child: CupertinoButton(
                      color: Colors.redAccent,
                      child: Text(
                        "Scan New Pass",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        String id = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => UserScan(widget.ref)),
                        );

                        if (id != "0") {
                          SharedPreferences prefs = await SharedPreferences.getInstance();

                          if (prefs.containsKey("wallet")) {
                            List<String>? codes = prefs.getStringList("wallet");
                            codes!.add(id);
                            prefs.setStringList("wallet", codes);
                          } else {
                            prefs.setStringList("wallet", [id]);
                          }

                          setState(() {});
                        }
                      }),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<SharedPreferences> pref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: () async => false, child: savedInvites());
  }
}
