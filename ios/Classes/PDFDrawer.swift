//
//  PDFDrawer.swift
//  PDFKit Demo
//
//  Created by Tim on 31/01/2019.
//  Copyright © 2019 Tim. All rights reserved.
//

import Foundation
import PDFKit

class PDFDrawer {
    weak var pdfView: PDFView!
    private var path: UIBezierPath?
    private var currentAnnotation : DrawingAnnotation?
    private var currentPage: PDFPage?
    var color = UIColor.red // default color is red
    var lineWidth: Int! = 5
    var pathArray = [[String:Any]]()
    var colorString: String!
    var currentPagePathArray : [[String:Any]]! {
        didSet {
            guard currentPagePathArray != nil else {
                return
            }
            currentAnnotation?.path.removeAllPoints()
            pathArray.removeAll()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.init(uptimeNanoseconds: UInt64(0.5)), execute: {
                for dict in self.currentPagePathArray {
                    let linePath = UIBezierPath()
                    let lineArray = dict["moves"] as? [[String:Any]] ?? [[String:Any]]()
                    linePath.move(to: CGPoint(x: lineArray[0]["dx"] as? Double ?? 0.0, y: lineArray[0]["dy"] as? Double ?? 0.0))
                    for path in lineArray {
                        linePath.addLine(to: CGPoint(x: path["dx"] as? Double ?? 0.0, y: path["dy"] as? Double ?? 0.0))
                        if self.currentAnnotation == nil {
                            let border = PDFBorder()
                            border.lineWidth = CGFloat(dict["paintWidth"] as? Int ?? 0)
                            let page = self.pdfView.currentPage ?? PDFPage()
                            self.currentAnnotation = DrawingAnnotation(bounds: page.bounds(for: self.pdfView.displayBox), forType: .ink, withProperties: nil)
                            self.currentAnnotation?.color = UIColor.colorWithHexString(hex: "#\(dict["paintColor"] as? Int ?? 0)").withAlphaComponent(1)
                            self.currentAnnotation?.border = border
                        }
                        self.currentAnnotation?.path = linePath
                        self.forceRedraw(annotation: self.currentAnnotation!, onPage: self.pdfView.currentPage ?? PDFPage())
                    }
                    self.currentAnnotation?.completed()
                    self.currentAnnotation = nil
                    self.pathArray.append(self.pathDict(pathArray: self.pathTransform(path: linePath)))
                }
            })
        }
    }
}

extension PDFDrawer: DrawingGestureRecognizerDelegate {
    func gestureRecognizerBegan(_ location: CGPoint) {
        guard let page = pdfView.page(for: location, nearest: true) else { return }
        currentPage = page
        let convertedPoint = pdfView.convert(location, to: currentPage!)
        path = UIBezierPath()
        path?.move(to: convertedPoint)
    }
    
    func gestureRecognizerMoved(_ location: CGPoint) {
        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)
        
        if lineWidth == 0 {
            removeAnnotationAtPoint(point: convertedPoint, page: page)
            return
        }
        
        path?.addLine(to: convertedPoint)
        path?.move(to: convertedPoint)
        drawAnnotation(onPage: page, path: path)
    }
    
    func gestureRecognizerEnded(_ location: CGPoint) {
        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)
        
        // Erasing
        if lineWidth == 0 {
            removeAnnotationAtPoint(point: convertedPoint, page: page)
            return
        }
        
        // Drawing
        guard let _ = currentAnnotation else { return }
        
        path?.addLine(to: convertedPoint)
        path?.move(to: convertedPoint)
        drawAnnotation(onPage: page, path: path)
        
        currentAnnotation?.completed()
        currentAnnotation = nil
        
        pathArray.append(pathDict(pathArray: pathTransform(path: path ?? UIBezierPath())))
        
    }
    
    private func createAnnotation(path: UIBezierPath, page: PDFPage) -> DrawingAnnotation {
        let border = PDFBorder()
        border.lineWidth = CGFloat(lineWidth)
        
        let annotation = DrawingAnnotation(bounds: page.bounds(for: pdfView.displayBox), forType: .ink, withProperties: nil)
        annotation.color = color.withAlphaComponent(1)
        annotation.border = border
        return annotation
    }
    
    private func drawAnnotation(onPage: PDFPage, path: UIBezierPath?) {
        guard let path = path else { return }
        
        if currentAnnotation == nil {
            currentAnnotation = createAnnotation(path: path, page: onPage)
        }
        currentAnnotation?.path = path
        forceRedraw(annotation: currentAnnotation!, onPage: onPage)
    }
    
    private func removeAnnotationAtPoint(point: CGPoint, page: PDFPage) {
        if let selectedAnnotation = page.annotationWithHitTest(at: point) {
            selectedAnnotation.page?.removeAnnotation(selectedAnnotation)
            removePath(annotation: selectedAnnotation)
        }
    }
    
    private func forceRedraw(annotation: PDFAnnotation, onPage: PDFPage) {
        onPage.removeAnnotation(annotation)
        onPage.addAnnotation(annotation)
    }
    
    func removePath(annotation: PDFAnnotation) {
        var removeArray = [[String:CGFloat]]()
        for path in annotation.paths ?? [UIBezierPath()] {
            removeArray = pathTransform(path: path)
        }
        for i in 0..<pathArray.count {
            if pathArray[i]["moves"] as? [[String:CGFloat]] == removeArray {
                pathArray.remove(at: i)
                return
            }
        }
    }
    
    func pathTransform(path: UIBezierPath) -> [[String:CGFloat]] {
        var tempArray = [[String:CGFloat]]()
        for point in path.cgPath.getPathElementsPoints() {
            var tempDict = [String:CGFloat]()
            tempDict["dx"] = point.x
            tempDict["dy"] = point.y
            tempArray.append(tempDict)
        }
        return tempArray
    }
    
    func pathDict(pathArray: [[String:CGFloat]]) -> [String: Any] {
        var tempDict = [String:Any]()
        tempDict["isEraser"] = false
        tempDict["mStandardH"] = 0
        tempDict["mStandardW"] = 0
        tempDict["moves"] = pathArray
        tempDict["oX"] = 0
        tempDict["oY"] = 0
        tempDict["paintColor"] = colorString
        tempDict["paintWidth"] = lineWidth
        tempDict["start"] = pathArray.first
        tempDict["end"] = pathArray.last
        return tempDict
    }
    
}

extension CGPath {
    func forEach( body: @escaping @convention(block) (CGPathElement) -> Void) {
        typealias Body = @convention(block) (CGPathElement) -> Void
        let callback: @convention(c) (UnsafeMutableRawPointer, UnsafePointer<CGPathElement>) -> Void = { (info, element) in
            let body = unsafeBitCast(info, to: Body.self)
            body(element.pointee)
        }
        let unsafeBody = unsafeBitCast(body, to: UnsafeMutableRawPointer.self)
        self.apply(info: unsafeBody, function: unsafeBitCast(callback, to: CGPathApplierFunction.self))
    }
    func getPathElementsPoints() -> [CGPoint] {
        var arrayPoints : [CGPoint]! = [CGPoint]()
        self.forEach { element in
            switch (element.type) {
            case CGPathElementType.moveToPoint:
                arrayPoints.append(element.points[0])
            case .addLineToPoint:
                arrayPoints.append(element.points[0])
            case .addQuadCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
            case .addCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
                arrayPoints.append(element.points[2])
            default: break
            }
        }
        return arrayPoints
    }
    func getPathElementsPointsAndTypes() -> ([CGPoint],[CGPathElementType]) {
        var arrayPoints : [CGPoint]! = [CGPoint]()
        var arrayTypes : [CGPathElementType]! = [CGPathElementType]()
        self.forEach { element in
            switch (element.type) {
            case CGPathElementType.moveToPoint:
                arrayPoints.append(element.points[0])
                arrayTypes.append(element.type)
            case .addLineToPoint:
                arrayPoints.append(element.points[0])
                arrayTypes.append(element.type)
            case .addQuadCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
                arrayTypes.append(element.type)
                arrayTypes.append(element.type)
            case .addCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
                arrayPoints.append(element.points[2])
                arrayTypes.append(element.type)
                arrayTypes.append(element.type)
                arrayTypes.append(element.type)
            default: break
            }
        }
        return (arrayPoints,arrayTypes)
    }
}
