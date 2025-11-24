//
//  ControlState.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/10/28.
//

import Foundation

enum ControlState {
    case idle
    
    case starting
    case running
    
    case pausing
    case paused
    
    /// 暂停恢复中
    case resuming
    
    case stopping
    case stopped
    
    case error
}

enum ControlStateError: Error {
    case invalid
}

protocol Controllable {
    var state: ControlState { get }
    var error: Error? { get set }
    
    func start(completion: ((Result<(), Error>) -> ())?)
    func pause(completion: ((Result<(), Error>) -> ())?)
    func resume(completion: ((Result<(), Error>) -> ())?)
    func stop(completion: ((Result<(), Error>) -> ())?)
}

extension Controllable {
    var state: ControlState { .idle }
    
    func start(completion: ((Result<(), Error>) -> ())?) {}
    func pause(completion: ((Result<(), Error>) -> ())?) {}
    func resume(completion: ((Result<(), Error>) -> ())?) {}
    func stop(completion: ((Result<(), Error>) -> ())?) {}
}

