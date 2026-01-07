//
//  NewRecordViewController.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2026/1/6.
//

import Cocoa

class NewRecordViewController: NSViewController {
    
    var selection: CaptureSelectionContext?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        view.layer?.cornerRadius = 15
    }
    
    @IBAction func backAction(_ sender: Any) {
        AppWindowCoordinator.shared.deactivateAndOrderOut(view.window?.nextResponder as? NSWindowController)
    }
    
    
    @IBAction func scrrenAction(_ sender: Any) {
        startSelection(with: .window)
    }
    
    @IBAction func windowAction(_ sender: Any) {
        startSelection(with: .window)
    }
    
    @IBAction func areaAction(_ sender: Any) {
        startSelection(with: .area)
    }
    
    func startSelection(with mode: CaptureSelectionContext.Mode) {
        selection = CaptureSelectionContext(mode: mode)
        selection?.delegate = self
        selection?.startSelection()
    }
    
}

extension NewRecordViewController: CaptureSelectionContextDelegate {
    
    func selectionDidFinish(result: CaptureSelectionContext.SelectionResult) {
         
    }
    
    func selectionDidCancel() {
        selection = nil
    }
}
