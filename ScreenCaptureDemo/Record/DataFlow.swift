//
//  CaptureType.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/10/29.
//

import Foundation
 
protocol CaptureSourceProtocol: Controllable {
    associatedtype Output
    
    /// 产生数据
    var onCapture: ((Output) -> ())? { get set }
}

protocol DataSinkProtocol: Controllable {
    associatedtype Input
    
    /// 接收数据
    func receive(_ input: Input) -> Bool
}

class CaptureSource<T>: CaptureSourceProtocol {
    typealias Output = T
    var error: Error?
    
    var onCapture: ((T) -> ())?
     
    private let stateLock = NSLock()
    private var _state: ControlState = .idle
    var state: ControlState {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _state
    }
    
    func setState(_ newState: ControlState, error: Error? = nil) {
        stateLock.lock()
        _state = newState
        self.error = error
        stateLock.unlock()
    } 
    
    func start(completion: ((Result<(), Error>) -> ())?) {
        guard state == .idle else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        setState(.running)
        completion?(.success(()))
    }
    func pause(completion: ((Result<(), Error>) -> ())?) {
        guard state == .running else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        setState(.paused)
        completion?(.success(()))
    }
    func resume(completion: ((Result<(), Error>) -> ())?) {
        guard state == .paused else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        
        setState(.running)
        completion?(.success(()))
    }
    func stop(completion: ((Result<(), Error>) -> ())?) {
        guard state != .idle else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        setState(.stopped)
        completion?(.success(()))
    }
}

class DataSink<T>: DataSinkProtocol {
    typealias Input = T
    var error: Error?
    
    func receive(_ input: T) -> Bool {
        true
    }
    
    private let stateLock = NSLock()
    private var _state: ControlState = .idle
    var state: ControlState {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _state
    }
    
    func setState(_ newState: ControlState, error: Error? = nil) {
        stateLock.lock()
        _state = newState
        self.error = error
        stateLock.unlock()
    }
    
    func start(completion: ((Result<(), Error>) -> ())?) {
        guard state == .idle else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        setState(.running)
        completion?(.success(()))
    }
    func pause(completion: ((Result<(), Error>) -> ())?) {
        guard state == .running else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        setState(.paused)
        completion?(.success(()))
    }
    func resume(completion: ((Result<(), Error>) -> ())?) {
        guard state == .paused else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        
        setState(.running)
        completion?(.success(()))
    }
    func stop(completion: ((Result<(), Error>) -> ())?) {
        guard state != .idle else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        setState(.stopped)
        completion?(.success(()))
    }
}
