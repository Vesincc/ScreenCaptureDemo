//
//  VideoCapture.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/10/29.
//

import AVFoundation
import ScreenCaptureKit

class VideoCapture: CaptureSource<CMSampleBuffer> {
    
    let source: VideoSource
    
    let deviceId: String?
    
    init(source: VideoSource, deviceId: String?) {
        self.source = source
        self.deviceId = deviceId
        super.init()
    }
    
    func start(completion: ((Result<(), any Error>) -> ())?) {
        
    }
    
    func pause(completion: ((Result<(), any Error>) -> ())?) {
        
    }
    
    func stop(completion: ((Result<(), any Error>) -> ())?) {
    
    }
    
}
