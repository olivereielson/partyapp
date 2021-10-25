import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class HostScan extends StatefulWidget {
  HostScan(
      {Key? key,
      required this.partyCode,
      required this.partyName,
      required this.analytics})
      : super(key: key);
  final String partyCode;
  final String partyName;
  final FirebaseAnalytics analytics;

  @override
  _HostScanState createState() => _HostScanState();
}

class _HostScanState extends State<HostScan> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool _scanning = false;
  String _homeID = "";
  bool flash = false;
  FirebasePerformance _performance = FirebasePerformance.instance;

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();

  String _message = "Scan Code";
  Color _messageColor = Colors.redAccent;

  SnackBar warning(String warning) {
    return SnackBar(
      content: Text(
        warning,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.redAccent,
      action: SnackBarAction(
        label: 'ok',
        textColor: Colors.white,
        onPressed: () {
          // Some code to undo the change.
        },
      ),
    );
  }

  String generateID() {
    var rng = new Random();

    String date = DateTime.now().microsecondsSinceEpoch.toString();

    String inviteID = widget.partyName.toUpperCase() +
        "-" +
        date.substring(date.length - 5) +
        "-" +
        rng.nextInt(100000).toString();

    print(inviteID);

    return inviteID;
  }

  Future<void> scandata(Barcode result, DocumentReference party) async {
    _scanning = true;
    final Trace trace = _performance.newTrace('host_scan');
    await trace.start();

    party.get().then((DocumentSnapshot documentSnapshot) async {
      if (documentSnapshot.data().toString().contains(result.code)) {
        try {
          if (documentSnapshot.get(result.code) == 0) {
            _messageColor = Colors.orangeAccent;
            _message = "Reused Code";
            widget.analytics.logEvent(
              name: 'invite_scanned',
              parameters: <String, dynamic>{
                'outcome': 'reused',
              },
            );
          }
          if (documentSnapshot.get(result.code) != 0 && documentSnapshot.get(result.code) != null) {
            if (documentSnapshot.get(result.code) > 1) {
              party.set({result.code: documentSnapshot.get(result.code) - 1},
                  SetOptions(merge: true));
            } else {
              party.set({result.code: 0}, SetOptions(merge: true));
            }

            party.set({"scans": documentSnapshot.get("scans") + 1},
                SetOptions(merge: true));

            setState(() {
              _messageColor = Colors.green;
              _message = "Approved";
              widget.analytics.logEvent(
                name: 'invite_scanned',
                parameters: <String, dynamic>{
                  'outcome': 'approved',
                },
              );
            });
          }
        } catch (e, s) {
          _messageColor = Colors.orangeAccent;
          _message = "Unknown Error";
          await FirebaseCrashlytics.instance.recordError(e, s, reason: 'Host Scan Failed');
        }
      } else {
        setState(() {
          _messageColor = Colors.orangeAccent;
          _message = "Rejected";
          widget.analytics.logEvent(
            name: 'invite_scanned',
            parameters: <String, dynamic>{
              'outcome': 'rejected',
            },
          );
        });
      }
    });
    await trace.stop();
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _message = "Scan Code";
      _messageColor = Colors.redAccent;
    });
    _scanning = false;
  }

  void _onQRViewCreated(QRViewController controller, DocumentReference party) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      if (!_scanning) {
        scandata(result!, party);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    DocumentReference party =
        FirebaseFirestore.instance.collection('party').doc(widget.partyName);
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: <Widget>[
              Stack(
                children: [
                  QRView(
                      key: qrKey,
                      onQRViewCreated: (cont) {
                        return _onQRViewCreated(cont, party);
                      }),
                ],
              ),
              Positioned(
                top: 0,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  height: 180,
                  width: MediaQuery.of(context).size.width,
                  decoration: new BoxDecoration(
                      color: _messageColor.withOpacity(0.9),
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
                                      'front': cf == CameraFacing.back
                                          ? true
                                          : false,
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        warning(
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
              ),
            ],
          ),
        ));
  }

  @override
  void initState() {
    _testSetCurrentScreen();
    super.initState();
    initConnectivity();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _testSetCurrentScreen() async {
    await widget.analytics.setCurrentScreen(
      screenName: 'Party Home Scan',
      screenClassOverride: 'party_home_scan',
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
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
    if (result == ConnectivityResult.none) {
      print("no internet");

      setState(() {
        _message = "No Internet";
        _messageColor = Colors.orangeAccent;
      });
    } else {
      setState(() {
        _message = "Scan Code";
        _messageColor = Colors.redAccent;
      });
    }
  }
}
