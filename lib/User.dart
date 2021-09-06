import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

class Userpage extends StatefulWidget {
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
      appBar: AppBar(
        title: Text("Saved Invites"),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 400,
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  height: 300,
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: ((MediaQuery.of(context).size.width - 300) / 2)),
                        child: Text(
                          "Lax Party",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: ((MediaQuery.of(context).size.width - 300) / 2)),
                        child: Text(
                          "November 3",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                      Center(
                        child: Card(
                          color: Colors.redAccent,
                          child: QrImage(
                            size: 300,
                            data: index.toString(),
                            foregroundColor: Colors.white,
                            version: QrVersions.auto,
                          ),
                        ),
                      ),
                    ],
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
        ],
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
