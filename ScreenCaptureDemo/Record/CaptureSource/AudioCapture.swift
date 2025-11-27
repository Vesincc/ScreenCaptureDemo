//
//  AudioCapture.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/11/26.
//

import Foundation
import AVFoundation

class AudioCapture: CaptureSource<CMSampleBuffer> {
    
    let deviceId: String?
    
    private let queue = DispatchQueue(label: "AudioCapture.queue", qos: .userInteractive)

    init(deviceId: String) {
        self.deviceId = deviceId
        
        let devices = AVCaptureDevice.devices(for: .audio)
        let device = devices.first(where: { $0.uniqueID == deviceId }) ?? AVCaptureDevice.default(for: .audio)
    }
    
}
