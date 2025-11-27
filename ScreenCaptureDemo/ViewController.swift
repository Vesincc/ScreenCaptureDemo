//
//  ViewController.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/10/25.
//

import Cocoa
import AVFoundation

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
    
}

