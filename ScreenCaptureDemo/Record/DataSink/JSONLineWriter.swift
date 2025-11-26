//
//  JSONLineWriter.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/11/25.
//

import Foundation

class JSONLineWriter: DataSink<Encodable> {
    
    private let outputURL: URL
    
    let jsonEncoder = JSONEncoder()
    let queue = DispatchQueue(label: "JSONLineWriter.queue", qos: .userInteractive)
    
    var handle: FileHandle?
    
    private var buffer: Data = Data()
    let maxBufferedBytes = 8 * 1024 // 8 KB
    
    init(outputURL: URL) {
        self.outputURL = outputURL
//        jsonEncoder.outputFormatting = .sortedKeys
    }
    
    override func receive(_ input: any Encodable) -> Bool {
        guard self.state == .running, handle != nil else {
            return false
        }
        queue.async {   
            autoreleasepool {
                do {
                    var data = try self.jsonEncoder.encode(input)
                    data.append(0x0A)
                    self.buffer.append(data)
                    
                    if self.buffer.count >= self.maxBufferedBytes {
                        self.flushBuffer()
                    }
                } catch {
                    print("error : \(error)")
                }
            }
        }
        return true
    }
    
    func flushBuffer() {
        guard let handle = handle, !buffer.isEmpty else {
            return
        }
        autoreleasepool {
            handle.write(buffer)
            buffer.removeAll(keepingCapacity: true)
        }
    }
    
    override func start(completion: ((Result<(), any Error>) -> ())?) {
        guard state == .idle else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        setState(.starting)
        FileManager.default.createFile(atPath: self.outputURL.path, contents: nil)
        do {
            handle = try FileHandle(forWritingTo: outputURL)
            setState(.running)
            completion?(.success(()))
        } catch {
            setState(.error, error: error)
            completion?(.failure(error))
        }
    }
    
    override func stop(completion: ((Result<(), any Error>) -> ())?) {
        guard state != .idle else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        setState(.stopping)
        queue.sync {
            self.flushBuffer()
            try? handle?.synchronize()
            try? handle?.close()
            handle = nil
        }
        
        setState(.stopped)
        completion?(.success(()))
    }
    
}
