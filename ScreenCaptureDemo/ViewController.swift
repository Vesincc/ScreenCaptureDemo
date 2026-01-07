//
//  ViewController.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/10/25.
//

import Cocoa
import AVFoundation
import ConeMacKit

class ViewController: NSViewController {

    let recoder = ScreenRecorder()
     
    var session: MediaCaptureSession?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("devices: \(AVCaptureDevice.default(for: .audio))")
    }
    
    
    @IBAction func startAction(_ sender: Any) {
        session = MediaCaptureSession(workspace: MediaWorkspace(workspace: URL(fileURLWithPath: "/Users/hanqi/Desktop/test")))
        session?.start { result in
            print("ViewController: \(result)")
        }
        
    }
    
    @IBAction func stopAction(_ sender: Any) {
        session?.stop { [weak self] result in
            print("ViewController: \(result)")
            self?.session = nil
        }
    }
    
    
    
    
    @IBAction func newRecordAction(_ sender: Any) {
        let storyboard = NSStoryboard(name: "NewRecord", bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: "NewRecordWindowController") as! NewRecordWindowController
        AppWindowCoordinator.shared.activate(windowController)
        windowController.window?.alignment(.bottom, offset: CGPoint(x: 0, y: 100))
    }
    
}

