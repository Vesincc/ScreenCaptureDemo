//
//  MediaWorkspace.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/11/24.
//

import Foundation

class MediaWorkspace {
      
    var workspace: URL
      
    init(workspace: URL) {
        self.workspace = workspace
    }
    
}


extension MediaWorkspace {
    
    /// 录制文件名字
    enum MediaFileName: String {
        case screen = "screen.mp4"
        
        case mouseMove = "mouse_moves.jsonl"
        case mouseClick = "mouse_clicks.jsonl"
        case cursorFolder = "cursor"
    }
    
    /// 录制目录
    var captureUrl: URL {
        workspace.appendingPathComponent("capture")
    }
    
    func captureUrl(for media: MediaFileName, checkExist: Bool = false) -> URL? {
        let mediaUrl = captureUrl.appendingPathComponent(media.rawValue)
        guard checkExist else {
            return mediaUrl
        }
        if FileManager.default.fileExists(atPath: mediaUrl.path) {
            return mediaUrl
        } else {
            return nil
        }
    }
    
}


extension MediaWorkspace {
    
    /// 重置当前Workspace, 删除当前路径 创建新的
    func resetWorkspace(completion: ((Error?) -> ())?) {
        do {
            if FileManager.default.fileExists(atPath: workspace.path) {
                try FileManager.default.removeItem(at: workspace)
            }
            try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
            
            /// 创建录制文件夹
            try FileManager.default.createDirectory(at: captureUrl, withIntermediateDirectories: true)
            
            completion?(nil)
        } catch {
            completion?(error)
        }
    }
    
}
