//
//  CaptureType.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/10/29.
//

import Foundation

enum VideoSource {
    case screen
    case window
    case camera
}

enum AudioSource {
    case system
    case microphone
}

enum InputSource {
    case mouseMove
    case mouseClick
    case cursor
    case keyboard
}

enum CaptureType {
    case video(VideoSource)
    case audio(AudioSource)
    case input(InputSource)
}


protocol CaptureSourceProtocol: Controllable {
    associatedtype Output
    
    /// 产生数据
    var onCapture: ((Output) -> ())? { get set }
}


class CaptureSource<T>: CaptureSourceProtocol {
    typealias Output = T
    var error: Error?
    
    var onCapture: ((T) -> ())?
    
    func start(completion: ((Result<(), any Error>) -> ())?) {
    }
    func pause(completion: ((Result<(), any Error>) -> ())?) {
    }
    func resume(completion: ((Result<(), any Error>) -> ())?) {
    }
    func stop(completion: ((Result<(), any Error>) -> ())?) {
    }
} 

protocol DataSinkProtocol: Controllable {
    associatedtype Input
    
    /// 接收数据
    func receive(_ input: Input) -> Bool
}
 

class DataSink<T>: DataSinkProtocol {
    typealias Input = T
    var error: Error?
    
    func receive(_ input: T) -> Bool {
        true
    }
    
    func start(completion: ((Result<(), any Error>) -> ())?) {
    }
    func pause(completion: ((Result<(), any Error>) -> ())?) {
    }
    func resume(completion: ((Result<(), any Error>) -> ())?) {
    }
    func stop(completion: ((Result<(), any Error>) -> ())?) {
    }
}
