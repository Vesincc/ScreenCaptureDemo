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
     
     
    private var stream: SCStream?
    private var display: SCDisplay?
    
    private let captureQueue = DispatchQueue(label: "VideoCapture.CaptureQueue", qos: .userInteractive)
    private lazy var handler: VideoCaptureHandler = {
        return VideoCaptureHandler(capture: self)
    }()
    
    
    init(source: VideoSource, deviceId: String?) {
        self.source = source
        self.deviceId = deviceId
        super.init()
    }
    
    override func start(completion: ((Result<(), any Error>) -> ())?) {
        print("准备捕捉屏幕...")
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: true) { content, error in
            if let error = error {
                completion?(.failure(error))
                return
            }
            guard let content = content else {
                print("无法获取共享内容")
                completion?(.failure(NSError(domain: "无法获取共享内容", code: -1)))
                return
            }
            guard let display = content.displays.first else {
                print("未找到显示器")
                completion?(.failure(NSError(domain: "未找到显示器", code: -1)))
                return
            }
            
            let displayScale = NSScreen.main?.backingScaleFactor ?? 1.0
            let nativeWidth = Int(CGFloat(display.width) * displayScale)
            let nativeHeight = Int(CGFloat(display.height) * displayScale)

            
            print("当前分辨率: \(display.width) x \(display.height)")
            print("显示器缩放比例: \(displayScale)")
            print("原生分辨率: \(nativeWidth) x \(nativeHeight)")

            
            let configer = SCStreamConfiguration()
            configer.width = nativeWidth
            configer.height = nativeHeight
            configer.scalesToFit = false
            configer.pixelFormat = kCVPixelFormatType_32BGRA
            configer.minimumFrameInterval = CMTime(value: 1, timescale: 60)
            configer.showsCursor = true
            configer.queueDepth = 6
            
            
            let filter = SCContentFilter(display: display, excludingWindows: [])
            
            do {
                let stream = SCStream(filter: filter, configuration: configer, delegate: self.handler)
                self.stream = stream
                
                try stream.addStreamOutput(self.handler, type: .screen, sampleHandlerQueue: self.captureQueue)
                
                stream.startCapture { error in
                    if let error = error {
                        completion?(.failure(error))
                    } else {
                        print("开始捕获屏幕 (\(nativeWidth)x\(nativeHeight))")
                        completion?(.success(()))
                    }
                }
                
            } catch {
                completion?(.failure(error))
            }
        }
    }
    
    override func pause(completion: ((Result<(), any Error>) -> ())?) {
        
    }
    
    override func stop(completion: ((Result<(), any Error>) -> ())?) {
        guard let stream = self.stream else {
            completion?(.failure(NSError(domain: "VideoCapture", code: -1, userInfo: [NSLocalizedDescriptionKey: "Stream not started"])))
            return
        }
        
        print("正在停止屏幕捕获...")
        
        stream.stopCapture { error in
            if let error = error {
                print("停止捕获失败：\(error.localizedDescription)")
                completion?(.failure(error))
            } else {
                print("屏幕捕获已停止")
                self.stream = nil
                completion?(.success(()))
            }
        }
    }
    
}

extension VideoCapture {
    
    private class VideoCaptureHandler: NSObject, SCStreamDelegate, SCStreamOutput {
        weak var capture: VideoCapture?
        
        init(capture: VideoCapture? = nil) {
            self.capture = capture
        }
        
        func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
            guard type == .screen else { return }
            capture?.onCapture?(sampleBuffer)
        }
    }
    
}
