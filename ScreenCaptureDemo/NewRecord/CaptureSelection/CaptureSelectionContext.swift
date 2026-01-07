//
//  CaptureSelectionContext.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2026/1/6.
//

import AppKit

protocol CaptureSelectionContextDelegate: AnyObject {
    func selectionDidFinish(result: CaptureSelectionContext.SelectionResult)
    func selectionDidCancel()
}
 
class CaptureSelectionContext {
    
    enum Mode {
        case screen
        case window
        case area
    }
    
    struct SelectionResult {
        var frame: CGRect
        var window: NSWindow?
        var screen: NSScreen?
    }
     
    let mode: Mode
    weak var delegate: CaptureSelectionContextDelegate?
    
    var selectionWindow: SelectionWindow?
    
    init(mode: Mode) {
        self.mode = mode
    }
    
    func startSelection() {
        selectionWindow = SelectionWindow(mode: self.mode)
        selectionWindow?.makeKeyAndOrderFront(nil)
    }
    
    func cancelSelection() {
        
    }
    
}
