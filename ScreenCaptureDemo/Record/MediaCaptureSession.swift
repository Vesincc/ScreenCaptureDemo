//
//  MediaCaptureSession.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/11/24.
//

import AppKit

protocol MediaCaptureSessionDelegate: NSObjectProtocol {
    func MediaCaptureSession(_ session: MediaCaptureSession, didChangeState: ControlState)
}

class MediaCaptureSession {
    
    enum SessionError: Error {
        case released
    }
      
    var workspace: MediaWorkspace
    
    var error: Error?
    
    /// 状态
    var _state: ControlState = .idle
    
    let stateLock = NSLock()
    var state: ControlState {
        stateLock.lock()
        let temp = _state
        stateLock.unlock()
        return temp
    }
    
    func setState(_ state: ControlState, error: Error? = nil) {
        stateLock.lock()
        _state = state
        self.error = error
        stateLock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.MediaCaptureSession(self, didChangeState: state)
        }
    }
    
    var streams: [Controllable] = []
    
    weak var delegate: MediaCaptureSessionDelegate?
     
    init(workspace: MediaWorkspace) {
        self.workspace = workspace
    }
    
    func initStreams() {
        streams.removeAll()
        
        let screenOutput = workspace.captureUrl(for: .screen, checkExist: false)!
        let screen = MediaStream(source: ScreenCapture(source: .screen(displayID: NSScreen.main?.displayID)), sink: MP4Writer(outputURL: screenOutput))
        streams.append(screen)
        
        let mouseMoveOutput = workspace.captureUrl(for: .mouseMove, checkExist: false)!
        let mouseMove = MediaStream(source: MouseEventCapture(captureType: .move), sink: JSONLineWriter(outputURL: mouseMoveOutput))
        streams.append(mouseMove)
        
        let mouseClickOutput = workspace.captureUrl(for: .mouseClick, checkExist: false)!
        let mouseClick = MediaStream(source: MouseEventCapture(captureType: .click), sink: JSONLineWriter(outputURL: mouseClickOutput))
        streams.append(mouseClick)
        
    }
    
} 

extension MediaCaptureSession: Controllable {
    
    func start(completion: ((Result<(), Error>) -> ())?) {
        guard state == .idle else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        
        setState(.starting)
        
        /// 重置workspace
        workspace.resetWorkspace { [weak self] error in
            
            guard let self = self else {
                completion?(.failure(SessionError.released))
                return
            }
            if let error = error {
                self.setState(.error, error: error)
                completion?(.failure(error))
                return
            }
            
            /// 初始化stream
            initStreams()
            
            /// 启动
            streams.operateAllStreams(.start) { result in
                switch result {
                case .success():
                    self.setState(.running)
                case .failure(let error):
                    self.setState(.error, error: error)
                }
                completion?(result)
            }
            
        }
    }
    
    func pause(completion: ((Result<(), Error>) -> ())?) {
        guard state == .running else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        
        setState(.pausing)
        
        streams.operateAllStreams(.pause) { [weak self] result in
            guard let self = self else {
                completion?(.failure(SessionError.released))
                return
            }
            switch result {
            case .success():
                self.setState(.paused)
            case .failure(let error):
                self.setState(.error, error: error)
            }
            completion?(result)
        }
    }
    
    func resume(completion: ((Result<(), Error>) -> ())?) {
        guard state == .paused else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        
        setState(.resuming)
        
        streams.operateAllStreams(.resume) { [weak self] result in
            guard let self = self else {
                completion?(.failure(SessionError.released))
                return
            }
            switch result {
            case .success():
                self.setState(.running)
            case .failure(let error):
                self.setState(.error, error: error)
            }
            completion?(result)
        }
        
    }
    
    func stop(completion: ((Result<(), Error>) -> ())?) {
        guard state != .idle else {
            completion?(.success(()))
            return
        }
        
        setState(.stopping)
        
        streams.operateAllStreams(.stop) { [weak self] result in
            guard let self = self else {
                completion?(.failure(SessionError.released))
                return
            }
            switch result {
            case .success():
                self.setState(.stopped)
            case .failure(let error):
                self.setState(.error, error: error)
            }
            completion?(result)
        }
    }
 
}
