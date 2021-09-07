import 'package:bouncer/UserScan.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
  bool _scanning = false;

  String _message = "Scan Code";
  Color _messageColor = Colors.redAccent;

  Scaffold savedInvites() {
    return Scaffold(

      body: SafeArea(
        bottom: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Row(
                children: [
                  Text(
                    "Saved Passes",
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),




            Container(
              width: MediaQuery.of(context).size.width,
              height: 250,

              child: Swiper(
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 100,
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.redAccent,
                      ),
                      child: Center(
                        child: QrImage(
                          size: 200,
                          data: index.toString(),
                          foregroundColor: Colors.white,
                          version: QrVersions.auto,
                        ),
                      ),
                    ),
                  );
                },
                itemCount: 3,
                pagination: SwiperPagination(),
                control: SwiperControl(
                  color: Colors.transparent,
                ),
              ),
            ),

            Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 90),
              child: CupertinoButton(

                color: Colors.redAccent,
                  child: Text("Scan New Pass",style: TextStyle(color: Colors.white),), onPressed: (){

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserScan(widget.ref)),
                );


              }),
            )


          ],
        ),
      ),
    );
  }


  Future<void> scandata(Barcode result) async {
    _scanning = true;

    setState(() {
      _messageColor=Colors.green;
      _message="Invite Saved";
    });


    await Future.delayed(Duration(seconds: 1));

    _scanning = false;
    setState(() {
      _messageColor=Colors.redAccent;
      _message="Scan Code";
    });

  }



  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      if (!_scanning) {
        scandata(result!);
      }
    });
  }

  Scaffold scanInvites(){

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
                width: MediaQuery.of(context).size.width,
                color: _messageColor,
                child: Center(
                    child: Text(
                      _message,
                      style: TextStyle(fontSize: 30),
                    ))),
          )
        ],
      ),
    );

  }

  @override
  Widget build(BuildContext context) {




    return PageView(
      scrollDirection: Axis.vertical,
      children: [
        savedInvites(),
        scanInvites()
      ],
    );
  }
}
