//
//  CursorImageWriter.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/11/27.
//

import Foundation
import AppKit

class CursorImageWriter: DataSink<Encodable> {
    
    var folder: URL
    
    let queue = DispatchQueue(label: "CursorImageWriter.queue", qos: .userInteractive)
    
    var writedIds: [String : Bool] = [:]
    
    init(folder: URL) {
        self.folder = folder
    }
    
    override func receive(_ input: any Encodable) -> Bool {
        guard let event = input as? MouseEventCapture.MouseEvent else {
            return false
        }
        guard !event.cursorId.isEmpty else {
            return false
        }
        guard state == .running else {
            return false
        }
        queue.async {
            guard let cursor = event.cursor else {
                return
            }
            guard self.writedIds[event.cursorId] == nil else {
                return
            }
            let image = cursor.image
            let named = event.cursorId + ".png"
            let fileUrl = self.folder.appendingPathComponent(named)
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                return
            }
            do {
                try pngData.write(to: fileUrl)
                self.writedIds[event.cursorId] = true
            } catch {
                print("cursor write error: \(error)")
            }
        }
        return true
    }
    
    
    override func start(completion: ((Result<(), any Error>) -> ())?) {
        do {
            if !FileManager.default.fileExists(atPath: folder.path) {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            }
        } catch {
            completion?(.failure(error))
            return
        }
        super.start(completion: completion)
    }
     
}
