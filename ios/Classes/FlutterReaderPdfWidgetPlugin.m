#import "FlutterReaderPdfWidgetPlugin.h"
#import <flutter_reader_pdf_widget/flutter_reader_pdf_widget-Swift.h>

@implementation FlutterReaderPdfWidgetPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [registrar registerViewFactory: [[SwiftFlutterReaderPdfWidgetPlugin alloc] initWithMessenger:[registrar messenger]] withId:@"flutter_reader_pdf_widget"];
}
@end
