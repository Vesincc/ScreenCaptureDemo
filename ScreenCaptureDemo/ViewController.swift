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
     
    let session = MediaCaptureSession(workspace: MediaWorkspace(workspace: URL(fileURLWithPath: "/Users/hanqi/Desktop/test")))
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func startAction(_ sender: Any) {
        session.start { result in
            print("ViewController: \(result)")
        }
    }
    
    @IBAction func stopAction(_ sender: Any) {
        session.stop { result in
            print("ViewController: \(result)")
        }
    }
    
}

