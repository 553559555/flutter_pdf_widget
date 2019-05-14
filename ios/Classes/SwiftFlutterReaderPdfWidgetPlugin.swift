import Flutter
import UIKit
import PDFKit

public class SwiftFlutterReaderPdfWidgetPlugin: NSObject, FlutterPlatformViewFactory {
    
    var messenger: FlutterBinaryMessenger!
    
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return PdfView(withFrame: frame, viewIdentifier: viewId, arguments: args, binaryMessenger: messenger)
    }
    
    @objc public init(messenger: (NSObject & FlutterBinaryMessenger)?) {
        super.init()
        self.messenger = messenger
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
  
}


public class PdfView: NSObject, FlutterPlatformView {
    
    
    fileprivate var viewId: Int64!;
    fileprivate var indicator: PDFView!
    fileprivate var channel: FlutterMethodChannel!
    fileprivate let pdfDrawer = PDFDrawer()
    fileprivate var isEdit = false
    fileprivate let pdfDrawingGestureRecognizer = DrawingGestureRecognizer()
    fileprivate var messageChannel: FlutterMethodChannel!
    
    public init(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?, binaryMessenger: FlutterBinaryMessenger) {
        super.init()
        let path = NSHomeDirectory() as NSString
        self.indicator = PDFView(frame: frame)
//        self.indicator.document = PDFDocument(url: URL(fileURLWithPath: path.appendingPathComponent(args as! String)))
        self.indicator.document = PDFDocument(url: URL(fileURLWithPath: Bundle.main.path(forResource: "Vim.pdf", ofType: nil) ?? ""))
        self.indicator.displayDirection = .horizontal
        self.indicator.usePageViewController(true, withViewOptions: nil)
        self.indicator.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.indicator.autoScales = true
        
        self.viewId = viewId
        self.channel = FlutterMethodChannel(name: "flutter_reader_pdf_widget_\(viewId)", binaryMessenger: binaryMessenger)
        
        self.channel.setMethodCallHandler({
            [weak self]
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if let this = self {
                this.onMethodCall(call: call, result: result)
            }
        })
        
        pdfDrawer.pdfView = self.indicator
        
        messageChannel = FlutterMethodChannel(name: "flutter_reader_pdf_widget_event", binaryMessenger: binaryMessenger)
        messageChannel.invokeMethod("getCurrentPage", arguments: 1) {
            (result: Any?) -> Void in
            self.pdfDrawer.currentPagePathArray = result as? Array
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(pdfViewChange(notification:)), name: NSNotification.Name.PDFViewPageChanged, object: nil)
    }
    
    @objc func pdfViewChange(notification: Notification) {
        messageChannel.invokeMethod("getCurrentPage", arguments: indicator.currentPage?.pageRef?.pageNumber) {
            (result: Any?) -> Void in
            self.pdfDrawer.currentPagePathArray = result as? Array
        }
    }
    
    public func view() -> UIView {
        return self.indicator
    }
    
    func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let method = call.method
        if method == "edit" {
            isEdit = !isEdit
            if isEdit {
                self.indicator.addGestureRecognizer(pdfDrawingGestureRecognizer)
                pdfDrawingGestureRecognizer.drawingDelegate = pdfDrawer
                pdfDrawer.pdfView = self.indicator
            } else {
                self.indicator.removeGestureRecognizer(pdfDrawingGestureRecognizer)
                // 需要上传的数组
                messageChannel.invokeMethod("getLinePath", arguments: pdfDrawer.pathArray)
            }
        } else if method == "changeLineSize" {
            pdfDrawer.lineWidth = call.arguments as? Int
        } else if method == "changeLineColor" {
            pdfDrawer.color = UIColor.colorWithHexString(hex: "#\(call.arguments ?? 0)")
            pdfDrawer.colorInt = call.arguments as? Int
        }
    }
    
}
