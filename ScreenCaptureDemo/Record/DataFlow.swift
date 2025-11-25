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
}

class DataSink<T>: DataSinkProtocol {
    typealias Input = T
    var error: Error?
    
    func receive(_ input: T) -> Bool {
        true
    }
}
