//
//  NewRecordWindowController.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2026/1/6.
//

import Cocoa

class NewRecordWindow: NSPanel {
    override var canBecomeKey: Bool {
        false
    }
    override var canBecomeMain: Bool {
        false
    }
}

class NewRecordWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.styleMask = [.nonactivatingPanel]
        window?.backgroundColor = .clear
        window?.isMovableByWindowBackground = true
        window?.level = .screenSaver
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

}
