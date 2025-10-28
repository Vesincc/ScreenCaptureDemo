//
//  DataStream.swift
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
}

class DataSink<T>: DataSinkProtocol {
    typealias Input = T
    var error: Error?
    
    func receive(_ input: T) -> Bool {
        true
    }
}

