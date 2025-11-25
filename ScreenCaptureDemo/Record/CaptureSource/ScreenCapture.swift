//
//  ScreenCapture.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/10/29.
//

import AVFoundation
import ScreenCaptureKit


extension NSScreen {
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}
 
extension SCDisplay {
    var screen: NSScreen? {
        NSScreen.screens.first(where: { $0.displayID == self.displayID } )
    }
}

struct ScreenCaptureConfiguration {
    var width: Int?
    var height: Int?
    var frameRate: Int = 60
    var pixelFormat: OSType = kCVPixelFormatType_32BGRA
    var showsCursor: Bool = false
    /// 缓冲帧数
    var queueDepth: Int = 6
    var colorSpace: CFString = CGColorSpace.sRGB
    
    func apply(to config: SCStreamConfiguration, display: SCDisplay) {
        let screen = display.screen
        let displayScale = screen?.backingScaleFactor ?? 1.0
        config.width = width ?? Int(CGFloat(display.width) * displayScale)
        config.height = height ?? Int(CGFloat(display.height) * displayScale)
        config.scalesToFit = false
        config.pixelFormat = pixelFormat
        config.minimumFrameInterval = CMTime(value: 1, timescale: Int32(frameRate))
        config.showsCursor = showsCursor
        config.queueDepth = queueDepth
        config.colorSpaceName = colorSpace
    }
}

class DefaultScreenContentProvider {
    func getContent(completion: @escaping (Result<SCShareableContent, Error>) -> ()) {
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: false) { content, error in
            if let error = error {
                completion(.failure(error))
            } else if let content = content {
                completion(.success(content))
            } else {
                completion(.failure(ScreenCaptureError.contentUnavailable))
            }
        }
    }
}

enum ScreenCaptureError: Error {
    case released
    case contentUnavailable
    case displayNotFound
    case streamNotStarted
}

enum ScreenSource {
    case screen(displayID: CGDirectDisplayID?)
    case window(window: NSWindow)
    case rect(displayID: CGDirectDisplayID?, rect: CGRect)
}

class ScreenCapture: CaptureSource<CMSampleBuffer> {
    
    let source: ScreenSource
    let deviceId: CGDirectDisplayID?
    let configuration: ScreenCaptureConfiguration
    let contentProvider: DefaultScreenContentProvider
     
    private let captureQueue = DispatchQueue(label: "ScreenCapture.CaptureQueue", qos: .userInteractive)
      
    private var stream: SCStream?
    private var display: SCDisplay?
    
    // 状态管理
    private let stateLock = NSLock()
    private var _state: ControlState = .idle
    var state: ControlState {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _state
    }
    
    
    private lazy var handler: VideoCaptureHandler = {
        return VideoCaptureHandler(capture: self)
    }()
     
    init(source: ScreenSource) {
        switch source {
        case .screen(let displayID):
            self.deviceId = displayID
        case .window(let window):
            self.deviceId = window.screen?.displayID
            let rect = window.convertToScreen(window.frame)
        case .rect(let displayID, let rect):
            self.deviceId = displayID
        }
        self.source = source 
        self.configuration = ScreenCaptureConfiguration()
        self.contentProvider = DefaultScreenContentProvider()
        super.init()
    }
    
    private func setState(_ newState: ControlState, error: Error? = nil) {
        stateLock.lock()
        _state = newState
        self.error = error
        stateLock.unlock()
    }
    
    private func createStreamConfiguration(for display: SCDisplay) -> SCStreamConfiguration {
        let config = SCStreamConfiguration()
        configuration.apply(to: config, display: display)
        return config
    }
    
    private func createContentFilter(for display: SCDisplay) -> SCContentFilter {
        return SCContentFilter(display: display, excludingWindows: [])
    }
    
    private func setupStream(display: SCDisplay) throws {
        let config = createStreamConfiguration(for: display)
        let filter = createContentFilter(for: display)
        
        let stream = SCStream(filter: filter, configuration: config, delegate: handler)
        try stream.addStreamOutput(handler, type: .screen, sampleHandlerQueue: captureQueue)
        
        self.stream = stream
        self.display = display
    }
    
    
    // MARK: - Controllable
    
    override func start(completion: ((Result<(), any Error>) -> ())?) {
        guard state == .idle else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        
        setState(.starting)
        
        
        contentProvider.getContent { [weak self] result in
            
            guard let self = self else {
                completion?(.failure(ScreenCaptureError.released))
                return
            }
            
            switch result {
            case .success(let content):
                
                guard let display = content.displays.first(where: { $0.displayID == self.deviceId }) else {
                    self.setState(.error, error: ScreenCaptureError.displayNotFound)
                    completion?(.failure(ScreenCaptureError.displayNotFound))
                    return
                }
                
                do {
                    
                    try self.setupStream(display: display)
                    self.stream?.startCapture { error in
                        
                        if let error = error {
                            self.setState(.error, error: error)
                            completion?(.failure(error))
                        } else {
                            self.setState(.running)
                            completion?(.success(()))
                        }
                        
                    }
                    
                } catch {
                    self.setState(.error, error: error)
                    completion?(.failure(error))
                }
                
            case .failure(let error):
                self.setState(.error, error: error)
                completion?(.failure(error))
            }
            
            
        }
         
    }
    
    override func pause(completion: ((Result<(), any Error>) -> ())?) {
        guard state == .running else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        setState(.paused)
        completion?(.success(()))
    }
    
    override func resume(completion: ((Result<(), any Error>) -> ())?) {
        guard state == .paused else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        
        setState(.running)
        completion?(.success(()))
    }
    
    override func stop(completion: ((Result<(), any Error>) -> ())?) {
        guard state != .idle else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        
        guard let stream = stream else {
            completion?(.failure(ScreenCaptureError.streamNotStarted))
            return
        }
        
        setState(.stopping)
        
        stream.stopCapture { [weak self] error in
            guard let self = self else {
                completion?(.failure(ScreenCaptureError.released))
                return
            }
            if let error = error {
                setState(.error, error: error)
                completion?(.failure(error))
            } else {
                self.stream = nil
                self.display = nil
                self.setState(.stopped)
                completion?(.success(()))
            }
        }
    }
    
}

extension ScreenCapture {
    
    private class VideoCaptureHandler: NSObject, SCStreamDelegate, SCStreamOutput {
        weak var capture: ScreenCapture?
        
        init(capture: ScreenCapture? = nil) {
            self.capture = capture
        }
        
        func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
            guard type == .screen else { return }
            capture?.onCapture?(sampleBuffer)
        }
    }
    
}
