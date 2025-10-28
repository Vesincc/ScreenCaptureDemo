//
//  ScreenRecorder.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/10/25.
//

import Foundation
import ScreenCaptureKit

class ScreenRecorder: NSObject {
    
    enum RecorderError: Error {
        case noDisplay
        case canNotAddInput
        case setupFailed
    }
    
    private var stream: SCStream?
    private var writer: AVAssetWriter?
    private var input: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var startTime: CMTime?
    
    func startRecording() async throws {
        print("准备捕捉屏幕...")
        
        
        
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first else {
            throw RecorderError.noDisplay
        }
        
        // 获取显示器的原生分辨率
        let nativeWidth = Int(CGFloat(display.width) * displayScale)
        let nativeHeight = Int(CGFloat(display.height) * displayScale)
        
        print("当前分辨率: \(display.width) x \(display.height)")
        print("显示器缩放比例: \(displayScale)")
        print("原生分辨率: \(nativeWidth) x \(nativeHeight)")
        
        let outputUrl = URL(fileURLWithPath: "/Users/hanqi/Desktop/screen_record.mp4")
        try? FileManager.default.removeItem(at: outputUrl)
        
        print("输出路径: \(outputUrl.path)")
        
        // 配置视频写入器 - 使用原生分辨率
        let writer = try AVAssetWriter(outputURL: outputUrl, fileType: .mp4)
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264, 
            AVVideoWidthKey: nativeWidth,
            AVVideoHeightKey: nativeHeight,
//            AVVideoCompressionPropertiesKey: [
//                AVVideoAverageBitRateKey: nativeWidth * nativeHeight * 10,
//                AVVideoMaxKeyFrameIntervalKey: 60
//            ]
        ]
        
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = true
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: nativeWidth,
            kCVPixelBufferHeightKey as String: nativeHeight,
            kCVPixelBufferBytesPerRowAlignmentKey as String: nativeWidth * 4
        ]
        
        guard writer.canAdd(input) else {
            throw RecorderError.canNotAddInput
        }
        
        writer.add(input)
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )
        
        self.writer = writer
        self.input = input
        self.adaptor = adaptor
        
        // 配置屏幕流 - 使用原生分辨率
        let config = SCStreamConfiguration()
        config.width = nativeWidth
        config.height = nativeHeight
        config.scalesToFit = false // 重要：不缩放
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        config.showsCursor = true
        config.queueDepth = 6
        config.colorSpaceName = CGColorSpace.displayP3 // 使用更广的色域
        
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let stream = SCStream(filter: filter, configuration: config, delegate: self)
        self.stream = stream
        
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .global(qos: .userInteractive))
        
        writer.startWriting()
        try await stream.startCapture()
        
        print("开始录制 - 分辨率: \(nativeWidth) x \(nativeHeight)")
    }
    
    // 获取显示器缩放比例
    private var displayScale: CGFloat {
        #if os(macOS)
        return NSScreen.main?.backingScaleFactor ?? 2.0
        #else
        return UIScreen.main.scale
        #endif
    }
    
    func stopRecording() async throws {
        print("停止录制")
        
        try await stream?.stopCapture()
        
        if let input = input, input.isReadyForMoreMediaData {
            input.markAsFinished()
        }
        
        await withCheckedContinuation { continuation in
            writer?.finishWriting {
                if let url = self.writer?.outputURL {
                    print("录制完成，文件保存至: \(url.path)")
                    
                    // 获取文件信息
                    let asset = AVAsset(url: url)
                    let tracks = asset.tracks(withMediaType: .video)
                    if let track = tracks.first {
                        let size = track.naturalSize
                        print("输出视频分辨率: \(Int(size.width)) x \(Int(size.height))")
                    }
                }
                continuation.resume()
            }
        }
        
        // 清理资源
        self.stream = nil
        self.writer = nil
        self.input = nil
        self.adaptor = nil
        self.startTime = nil
    }
}

extension ScreenRecorder: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        guard let writer = writer, writer.status == .writing else { return }
        guard let input = input, input.isReadyForMoreMediaData else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // 初始化开始时间
        if startTime == nil {
            startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            writer.startSession(atSourceTime: startTime!)
        }
        
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if adaptor?.append(pixelBuffer, withPresentationTime: presentationTime) == false {
            print("追加帧失败，错误: \(writer.error?.localizedDescription ?? "未知错误")")
        }
    }
}

extension ScreenRecorder: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("屏幕流停止，错误: \(error.localizedDescription)")
    }
}
