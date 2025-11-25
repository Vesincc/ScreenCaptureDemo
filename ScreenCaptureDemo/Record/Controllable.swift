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
}

extension Array where Element == Controllable {
     
    enum ControllableOperate {
        case start
        case pause
        case resume
        case stop
    }
    
    func operateAllStreams(_ operate: ControllableOperate, completion: ((Result<(), Error>) -> ())? ) {
        guard !self.isEmpty else {
            completion?(.success(()))
            return
        }
        
        let group = DispatchGroup()
        var error: Error?
        let lock = NSLock()
        
        for item in self {
            
            group.enter()
            var op: (((Result<(), Error>) -> ())?) -> ()
            switch operate {
            case .start:
                op = item.start
            case .pause:
                op = item.pause
            case .resume:
                op = item.resume
            case .stop:
                op = item.stop
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
