//
//  MediaCaptureSession.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/11/24.
//

import Foundation

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
        let screen = MediaStream(source: VideoCapture(source: .screen, deviceId: nil), sink: MP4Writer(outputURL: screenOutput))
        streams.append(screen)
    }
    
}

private extension MediaCaptureSession {
    
    enum StreamOperate {
        case start
        case pause
        case resume
        case stop
    }
     
    func operateAllStreams(_ operate: StreamOperate, completion: ((Result<(), Error>) -> ())? ) {
        guard !streams.isEmpty else {
            completion?(.success(()))
            return
        }
        
        let group = DispatchGroup()
        var error: Error?
        let lock = NSLock()
        
        for stream in streams {
            
            group.enter()
            var op: (((Result<(), Error>) -> ())?) -> ()
            switch operate {
            case .start:
                op = stream.start
            case .pause:
                op = stream.pause
            case .resume:
                op = stream.resume
            case .stop:
                op = stream.stop
            }
            
            op { result in
                switch result {
                case .success():
                    break
                case .failure(let e):
                    lock.lock()
                    error = e
                    lock.unlock()
                }
                group.leave()
            }
            
        }
        
        group.notify(queue: .main) {
            if let error = error {
                completion?(.failure(error))
            } else {
                completion?(.success(()))
            }
        }
        
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
            operateAllStreams(.start) { result in
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
        
        operateAllStreams(.pause) { [weak self] result in
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
        
        operateAllStreams(.resume) { [weak self] result in
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
        
        operateAllStreams(.stop) { [weak self] result in
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
