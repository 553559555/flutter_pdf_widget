import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reader_pdf_widget/flutter_reader_pdf_widget.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_reader_pdf_widget');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
//    expect(await FlutterReaderPdfWidget.platformVersion, '42');
  });
}
