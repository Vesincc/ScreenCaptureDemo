//
//  MediaStream.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/10/25.
//

import AVFoundation 

class MediaStream<T>: Controllable {
     
    var source: CaptureSource<T>
    var sinks: [DataSink<T>]
      
    var error: Error?
    
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
    }
    
    convenience init(source: CaptureSource<T>, sink: DataSink<T>) {
        self.init(source: source, sinks: [sink])
    }
    
    init(source: CaptureSource<T>, sinks: [DataSink<T>]) {
        self.source = source
        self.sinks = sinks
        connect()
    }
    
    func connect() {
        source.onCapture = { [weak self] output in
            guard let self = self else { return }
            for sink in self.sinks {
                _ = sink.receive(output)
            }
        }
    }
    
    func start(completion: ((Result<(), Error>) -> ())?) {
        guard state == .idle else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        
        setState(.starting)
        
        var nodes: [Controllable] = [source]
        nodes.append(contentsOf: sinks)
        
        nodes.operateAllStreams(.start) { [weak self] result in
            guard let self = self else {
                completion?(.failure(ControlStateError.invalid))
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
    
    func pause(completion: ((Result<(), Error>) -> ())?) {
        guard state == .running else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        
        setState(.pausing)
        
        var nodes: [Controllable] = [source]
        nodes.append(contentsOf: sinks)
        
        nodes.operateAllStreams(.pause) { [weak self] result in
            guard let self = self else {
                completion?(.failure(ControlStateError.invalid))
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
        
        var nodes: [Controllable] = [source]
        nodes.append(contentsOf: sinks)
        
        nodes.operateAllStreams(.resume) { [weak self] result in
            guard let self = self else {
                completion?(.failure(ControlStateError.invalid))
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
        
        var nodes: [Controllable] = [source]
        nodes.append(contentsOf: sinks)
        
        nodes.operateAllStreams(.stop) { [weak self] result in
            guard let self = self else {
                completion?(.failure(ControlStateError.invalid))
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
