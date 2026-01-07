//
//  SelectionOverlayView.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2026/1/6.
//

import AppKit

class SelectionOverlayView: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configerView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configerView()
    }
    
    func configerView() {
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.backgroundColor = NSColor.cyan.withAlphaComponent(0.1).cgColor
    }
    
}
