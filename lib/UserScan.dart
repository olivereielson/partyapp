import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bouncer/partyStructure.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class UserScan extends StatefulWidget {
  UserScan({required this.analytics});

  final FirebaseAnalytics analytics;

  @override
  _UserScanState createState() => _UserScanState();
}

class _UserScanState extends State<UserScan> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR2');

  Barcode? result;
  Color _mesageColor = Colors.redAccent;
  String _message = "Scan Code";
  QRViewController? controller;
  bool flash = false;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  bool _scanning = false;

  String generateID(String name){

    var rng = new Random();


    String date =DateTime.now().microsecondsSinceEpoch.toString();

    String inviteID = name.toUpperCase()+"-"+date.substring(date.length-5)+ "-"+rng.nextInt(100000).toString();

    print(inviteID);

    return inviteID;


  }

  Future<void> scandata(Barcode result) async {
    _scanning = true;

    if (result.code.split(",").length==3) {
      FirebaseFirestore.instance
          .collection('party')
          .doc(result.code.split(",")[0])
          .get()
          .then((DocumentSnapshot documentSnapshot) async {
        if (documentSnapshot.exists &&
            documentSnapshot.get("password") == result.code.split(",")[1]) {

          setState(() {
            _mesageColor = Colors.green;
            _message = "Accepted";
          });
          await Future.delayed(Duration(milliseconds: 500));

          String id=generateID(result.code.split(",")[0]);

          FirebaseFirestore.instance.collection('party').doc(result.code.split(",")[0]).set({id: result.code.split(",")[2]},SetOptions(merge: true));
          FirebaseFirestore.instance.collection('party').doc(result.code.split(",")[0]).set({"invites": FieldValue.increment(1)},SetOptions(merge: true));




          Navigator.pop(context, id);

        } else {
          setState(() {
            _mesageColor = Colors.orangeAccent;
            _message = "Invalid Code";
          });
        }
      });
    }

    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _mesageColor = Colors.redAccent;
      _message = "Scan Code";
    });
    _scanning = false;
  }

  SnackBar warning(String warning) {
    return SnackBar(
      content: Text(
        warning,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.redAccent,
      padding: EdgeInsets.all(8.0),

      action: SnackBarAction(
        label: 'ok',
        textColor: Colors.white,
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      result = scanData;

      print("scanned");
      if (!_scanning) {
        scandata(result!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
            Container(
              height: 180,
              width: MediaQuery.of(context).size.width,
              decoration: new BoxDecoration(
                  color: _mesageColor.withOpacity(0.9),
                  borderRadius: new BorderRadius.only(
                    bottomLeft: const Radius.circular(40.0),
                    bottomRight: const Radius.circular(40.0),
                  )),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context, "0");
                      },
                      icon: Icon(
                        Icons.arrow_back_outlined,
                        size: 30,
                      )),
                  Text(
                    _message,
                    style: TextStyle(fontSize: 30),
                  ),
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                            onPressed: () async {
                              await controller!.flipCamera();
                              await controller!.resumeCamera();
                              CameraFacing cf =
                                  await controller!.getCameraInfo();
                              widget.analytics.logEvent(
                                name: 'camera_flipped',
                                parameters: <String, dynamic>{
                                  'front':
                                      cf == CameraFacing.back ? true : false,
                                },
                              );
                            },
                            icon: Icon(Icons.flip_camera_ios)),
                        IconButton(
                            onPressed: () async {
                              if (await controller!.getCameraInfo() ==
                                  CameraFacing.back) {
                                await controller!.toggleFlash();
                                widget.analytics.logEvent(
                                  name: 'flash_toggled',
                                  parameters: <String, dynamic>{
                                    'flash': flash,
                                    'success': true
                                  },
                                );
                              } else {

                                
                                ScaffoldMessenger.of(context).showSnackBar(warning(
                                    "Flash can only be used with front camera"));
                                widget.analytics.logEvent(
                                  name: 'flash_toggled',
                                  parameters: <String, dynamic>{
                                    'flash': flash,
                                    'success': false
                                  },
                                );
                              }

                              flash = (await controller!.getFlashStatus())!;
                              setState(() {});
                            },
                            icon: Icon(flash
                                ? Icons.flashlight_on
                                : Icons.flashlight_off)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testSetCurrentScreen() async {
    await widget.analytics.setCurrentScreen(
      screenName: 'User Scan Page',
      screenClassOverride: 'UserScanPage',
    );
  }

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _testSetCurrentScreen();

  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
      return;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {


    if(result==ConnectivityResult.none){

      print("no internet");

      setState(() {
        _message = "No Internet";
        _mesageColor = Colors.orangeAccent;
      });
    }else{

      setState(() {
        _message = "Scan Code";
        _mesageColor = Colors.redAccent;
      });



    }

  }
}
