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
    
    
    let stream = MediaStream(source: VideoCapture(source: .screen, deviceId: nil), sink: MP4Writer(outputURL: URL(fileURLWithPath: "/Users/hanqi/Desktop/test.mp4")))
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        MediaStream<CMSampleBuffer>(source: VideoCapture(), sinks: [MediaWriter(), AudioWriter()])
//        MediaStream<CMSampleBuffer>(source: <#T##any CaptureSource#>, sinks: <#T##[any DataSink]#>)
    }
    
    
    @IBAction func startAction(_ sender: Any) {
//        Task {
//            do {
//                try await recoder.startRecording()
//            } catch {
//                print("error: \(error)")
//            }
//        }
        stream.start { result in
            print("ViewController: \(result)")
        }
    }
    
    @IBAction func stopAction(_ sender: Any) {
//        Task {
//            do {
//                try await recoder.stopRecording()
//            } catch {
//                print("error: \(error)")
//            }
//        }
        stream.stop { result in
            print("ViewController: \(result)")
        }
    }
    
}

