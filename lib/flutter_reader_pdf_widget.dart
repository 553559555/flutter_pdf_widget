import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _viewType = 'flutter_reader_pdf_widget';

typedef void PdfVieControllerwWidgetCreatedCallback(
    PdfViewController controller);

class UIReaderPDFWidget extends StatefulWidget {
  final PdfVieControllerwWidgetCreatedCallback onActivityIndicatorWidgetCreated;
  // pdf路径参数
  final param;
  final CallFlutterLocal callFlutterLocal;

  const UIReaderPDFWidget(
      {Key key,
      this.onActivityIndicatorWidgetCreated,
      this.param,
      this.callFlutterLocal})
      : super(key: key);

  _UIReaderPDFWidgetState createState() => _UIReaderPDFWidgetState();
}

class _UIReaderPDFWidgetState extends State<UIReaderPDFWidget> {
  // 注册一个通知
  // static const EventChannel eventChannel =
  //     const EventChannel('flutter_reader_pdf_widget/native_post');

  static const messageChannel =
      MethodChannel("flutter_reader_pdf_widget_event");

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    messageChannel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'getLinePath':
          print(call.arguments);
          widget.callFlutterLocal.getLinePath(call.arguments);
          break;
        case 'getCurrentPage':
          print(call.arguments);
          return await widget.callFlutterLocal.getCurrentPage(call.arguments);
          case 'getCurrentPageCount':
          print(call.arguments);
          break;
        default:
          throw MissingPluginException();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: _viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParamsCodec: new StandardMessageCodec(),
        creationParams: widget.param,
      );
    }
    return Text(
        '$defaultTargetPlatform is not yet supported by the activity_indicator plugin');
  }

  void _onPlatformViewCreated(int id) {
    if (widget.onActivityIndicatorWidgetCreated == null) {
      return;
    }
    widget.onActivityIndicatorWidgetCreated(new PdfViewController._(id));
  }
}

class PdfViewController {
  PdfViewController._(int id)
      : _channel = MethodChannel('flutter_reader_pdf_widget_$id');

  final MethodChannel _channel;

  Future<void> edit() async {
    return _channel.invokeMethod('edit');
  }

  Future<void> changeLineSize(int lineWidth) async {
    return _channel.invokeMethod('changeLineSize', lineWidth);
  }

  Future<void> changeLineColor(String lineColor) async {
    return _channel.invokeMethod('changeLineColor', lineColor);
  }
}

class CallFlutterLocal {
  final FutureOr<void> Function(List<Map<String, dynamic>>) getLinePath;
  final FutureOr<List<Map<String, dynamic>>> Function(int pageNum)
      getCurrentPage;

  CallFlutterLocal({@required this.getLinePath, @required this.getCurrentPage});
}
