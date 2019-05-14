import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_reader_pdf_widget/flutter_reader_pdf_widget.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  PdfViewController controller;

  void _onActivityIndicatorControllerCreated(PdfViewController _controller) {
    controller = _controller;
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
//      platformVersion = await FlutterReaderPdfWidget.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Stack(children: <Widget>[
          UIReaderPDFWidget(onActivityIndicatorWidgetCreated: _onActivityIndicatorControllerCreated,),
          FlatButton(onPressed: (){ controller.edit(); controller.changeLineColor(123456); controller.changeLineSize(10); },child: Text('click'),),
          Padding(
            padding: const EdgeInsets.only(left:100.0),
            child: FlatButton(onPressed: (){  controller.changeLineSize(0); },child: Text('changeWidth'),),
          ),
        ],)
      ),
    );
  }
}
