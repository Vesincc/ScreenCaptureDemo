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
    
    private var _state: ControlState = .idle
    private let stateLock = NSLock()
    
    var state: ControlState {
        stateLock.lock()
        
        defer {
            stateLock.unlock()
        }
        return _state
    }
    
    var error: Error?
    
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
        stateLock.lock()
        guard _state == .idle else {
            stateLock.unlock()
            completion?(.failure(NSError(domain: "MediaStream", code: 1,
                                         userInfo: [NSLocalizedDescriptionKey: "Cannot start from state \(_state)"])))
            return
        }
        _state = .starting
        stateLock.unlock()
        
        // 启动 source 和 sinks
        var startError: Error?
        let group = DispatchGroup()
        
        group.enter()
        source.start { result in
            if case .failure(let error) = result { startError = error }
            group.leave()
        }
        
        for sink in sinks {
            group.enter()
            sink.start { result in
                if case .failure(let error) = result { startError = error }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.stateLock.lock()
            if let error = startError {
                self._state = .error
                self.error = error
                self.stateLock.unlock()
                completion?(.failure(error))
            } else {
                self._state = .running
                self.stateLock.unlock()
                completion?(.success(()))
            }
        }
    }
    
    func pause(completion: ((Result<(), Error>) -> ())?) {
        stateLock.lock()
        guard _state == .running else {
            stateLock.unlock()
            completion?(.failure(NSError(domain: "MediaStream", code: 2,
                                         userInfo: [NSLocalizedDescriptionKey: "Cannot pause from state \(_state)"])))
            return
        }
        _state = .pausing
        stateLock.unlock()
        
        var pauseError: Error?
        let group = DispatchGroup()
        
        group.enter()
        source.pause { result in
            if case .failure(let error) = result { pauseError = error }
            group.leave()
        }
        
        for sink in sinks {
            group.enter()
            sink.pause { result in
                if case .failure(let error) = result { pauseError = error }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.stateLock.lock()
            if let error = pauseError {
                self._state = .error
                self.error = error
                self.stateLock.unlock()
                completion?(.failure(error))
            } else {
                self._state = .paused
                self.stateLock.unlock()
                completion?(.success(()))
            }
        }
    }
    
    func resume(completion: ((Result<(), Error>) -> ())?) {
        stateLock.lock()
        guard _state == .paused else {
            stateLock.unlock()
            completion?(.failure(NSError(domain: "MediaStream", code: 3,
                                         userInfo: [NSLocalizedDescriptionKey: "Cannot resume from state \(_state)"])))
            return
        }
        _state = .resuming
        stateLock.unlock()
        
        var resumeError: Error?
        let group = DispatchGroup()
        
        group.enter()
        source.start { result in
            if case .failure(let error) = result { resumeError = error }
            group.leave()
        }
        
        for sink in sinks {
            group.enter()
            sink.start { result in
                if case .failure(let error) = result { resumeError = error }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.stateLock.lock()
            if let error = resumeError {
                self._state = .error
                self.error = error
                self.stateLock.unlock()
                completion?(.failure(error))
            } else {
                self._state = .running
                self.stateLock.unlock()
                completion?(.success(()))
            }
        }
    }
    
    func stop(completion: ((Result<(), Error>) -> ())?) {
        stateLock.lock()
        guard _state != .stopped && _state != .idle else {
            stateLock.unlock()
            completion?(.success(()))
            return
        }
        _state = .stopping
        stateLock.unlock()
        
        let group = DispatchGroup()
        
        for sink in sinks {
            group.enter()
            sink.stop { _ in group.leave() }
        }
        
        group.enter()
        source.stop { _ in group.leave() }
        
        group.notify(queue: .main) {
            self.stateLock.lock()
            self._state = .stopped
            self.stateLock.unlock()
            completion?(.success(()))
        }
    }
}
