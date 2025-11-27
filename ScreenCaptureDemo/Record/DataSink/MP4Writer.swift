//
//  MP4Writer.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/11/6.
//

import Foundation
import AVFoundation

class MP4Writer: DataSink<CMSampleBuffer> { 
    
    private var writer: AVAssetWriter?
    private var input: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
 
    private let writingQueue = DispatchQueue(label: "MP4Writer.queue", qos: .userInitiated)
 
    private let outputURL: URL
    
    var firstPts: CMTime?
    
    init(outputURL: URL) {
        self.outputURL = outputURL
    }
    
    override func start(completion: ((Result<(), any Error>) -> ())?) {
        writingQueue.async {
            do {
                try? FileManager.default.removeItem(at: self.outputURL)
                
                let writer = try AVAssetWriter(outputURL: self.outputURL, fileType: .mp4)
                
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: 3840,
                    AVVideoHeightKey: 2160,
                    AVVideoCompressionPropertiesKey: [
                        AVVideoAverageBitRateKey: 45_000_000,
                        AVVideoMaxKeyFrameIntervalKey: 60
                    ]
                ]
                 
                
                let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                input.expectsMediaDataInRealTime = true
                 
                guard writer.canAdd(input) else {
                    throw NSError(domain: "MP4Writer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot add video input"])
                }
                
                writer.add(input)
                
                self.adaptor = AVAssetWriterInputPixelBufferAdaptor(
                    assetWriterInput: input,
                    sourcePixelBufferAttributes: [
                        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                        kCVPixelBufferWidthKey as String: 5120,
                        kCVPixelBufferHeightKey as String: 2880
                    ]
                )
                
                
                writer.startWriting()
                
                self.writer = writer
                self.input = input
                
                completion?(.success(()))
                print("MP4Writer started -> \(self.outputURL.path)")
            } catch {
                completion?(.failure(error))
            }
            
        }
    }
    
    override func receive(_ input: CMSampleBuffer) -> Bool {
        let sampleBuffer = input
        
        guard let writer = self.writer,
              let input = self.input,
              let adaptor = self.adaptor else { return false }
        
        guard writer.status == .writing,
              input.isReadyForMoreMediaData else { return false }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return false }
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        writingQueue.async {
            // start session at first frame
            if self.firstPts == nil {
                self.firstPts = pts
                writer.startSession(atSourceTime: pts)
            }
            
            // append pixel buffer
            adaptor.append(pixelBuffer, withPresentationTime: pts)
        }
        
        return true
    }
      
    override func stop(completion: ((Result<(), any Error>) -> ())?) {
        writingQueue.async {
            guard let writer = self.writer, let input = self.input else {
                completion?(.failure(NSError(domain: "MP4Writer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Writer not initialized"])))
                return
            }
            
            print("MP4Writer stopping...")
            if input.isReadyForMoreMediaData {
                input.markAsFinished()
            }
            print("MP4Writer stop(): writer.status = \(writer.status.rawValue)")
            writer.finishWriting {
                if writer.status == .completed {
                    print("✅ MP4Writer finished successfully: \(self.outputURL.path)")
                    completion?(.success(()))
                } else if let error = writer.error {
                    print("❌ MP4Writer failed: \(error.localizedDescription)")
                    completion?(.failure(error))
                } else {
                    print("⚠️ MP4Writer finished with unknown status: \(writer.status.rawValue)")
                    completion?(.failure(NSError(domain: "MP4Writer", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unknown finish status"])))
                }
                
                self.writer = nil
                self.input = nil
                self.firstPts = nil
            }
        }
    }
    
}
