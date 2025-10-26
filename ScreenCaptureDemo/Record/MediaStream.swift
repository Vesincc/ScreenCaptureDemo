//
//  MediaStream.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/10/25.
//

import AVFoundation

enum ControlState {
    case idle
    case starting
    case running
    case pausing
    case paused
    case stopping
    case stopped
    
    case error(Error)
}

protocol Controllable {
    var state: ControlState { get }
    
    func start(completion: ((Result<Void, Error>) -> ())?)
    func pause(completion: ((Result<Void, Error>) -> ())?)
    func stop(completion: ((Result<Void, Error>) -> ())?)
}

protocol CaptureSource: Controllable {
    var onSampleBuffer: ((CMSampleBuffer) -> Void)? { get set }
}

protocol MediaFilter {
    
}

protocol MediaWriter: Controllable {
    func appendSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> Bool
}


protocol MediaStreamDelegate: AnyObject {
    func mediaStream(_ stream: MediaStream, didChangeState state: ControlState)

}

class MediaStream {
    
    var state: ControlState = .idle
     
    private(set) var source: CaptureSource
    private(set) var writer: MediaWriter
    
    weak var delegate: MediaStreamDelegate?
    
    init(source: CaptureSource, writer: MediaWriter) {
        self.source = source
        self.writer = writer
        
        self.source.onSampleBuffer = { [weak self] buffer in
            _ = self?.writer.appendSampleBuffer(buffer)
        }
    }
    
}

extension MediaStream: Controllable {
    
    
    func start(completion: ((Result<Void, any Error>) -> ())?) {
         
    }
    
    func pause(completion: ((Result<Void, any Error>) -> ())?) {
         
    }
    
    func stop(completion: ((Result<Void, any Error>) -> ())?) {
         
    }
    
}
