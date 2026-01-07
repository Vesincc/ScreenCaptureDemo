//
//  MainWindowController.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2026/1/6.
//

import Cocoa

class MainWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        AppWindowCoordinator.shared.add(self)
    }

}
