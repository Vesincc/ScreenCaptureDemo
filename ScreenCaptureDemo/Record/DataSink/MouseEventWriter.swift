//
//  MouseEventWriter.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/11/27.
//

import Foundation

class MouseEventWriter: JSONLineWriter {
    
    enum WriteEventType {
        case all
        case move
        case click
    }
    
    var writeType: WriteEventType
    
    override func receive(_ input: any Encodable) -> Bool {
        guard let event = input as? MouseEventCapture.MouseEvent else {
            return false
        }
        var accepts: [MouseEventCapture.MouseEvent.EventType] = []
        switch writeType {
        case .all:
            accepts = MouseEventCapture.MouseEvent.EventType.allCases
        case .move:
            accepts = [.mouseMoved, .mouseDragged]
        case .click:
            accepts = [.mouseUp, .mouseDown]
        }
        guard accepts.contains(event.type) else {
            return false
        }
        return super.receive(input)
    }
    
    init(writeType: WriteEventType, outputURL: URL) {
        self.writeType = writeType
        super.init(outputURL: outputURL)
    }
}
