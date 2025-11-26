//
//  MouseEventCapture.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/11/25.
//

import AppKit

extension NSEvent.EventType {
    var mouseType: String {
        switch self {
        case .mouseMoved:
            return "mouseMoved"
        case .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            return "mouseDragged"
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            return "mouseDown"
        case .leftMouseUp, .rightMouseUp, .otherMouseUp:
            return "mouseUp"
        default:
            return "mouseMoved"
        }
    }
}

extension NSCursor {
    
    
    
}

class MouseEventCapture: CaptureSource<Encodable> {
    
    struct MouseEvent: Codable {
        let type: String
        let time: Double
        let x: CGFloat
        let y: CGFloat
        
        var cursorId: String
        var cursor: NSCursor?
        
        enum CodingKeys: CodingKey {
            case type
            case time
            case x
            case y
            case cursorId
        }
        
        init(with event: NSEvent?, cursor: NSCursor) {
            self.cursor = cursor
            let point = NSEvent.mouseLocation
            
            time = CACurrentMediaTime()
            type = event?.type.mouseType ?? "mouseMoved"
            x = point.x
            y = point.y
            cursorId = ""
        }
    }
    
    
    static var moveEventTypeMask: NSEvent.EventTypeMask {
        [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
    }
    
    static var clickEventTypeMask: NSEvent.EventTypeMask {
        [.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp]
    }
    
     
    enum MouseEventType {
        case move
        case click
        case cursor
    }
    
    var captureType: MouseEventType
    
    let queue = DispatchQueue(label: "MouseEventCapture.queue", qos: .userInteractive)
    
    var globalMonitor: Any?
    var localMonitor: Any?
    
    
    init(captureType: MouseEventType) {
        self.captureType = captureType
        super.init()
    }
    
    var eventTypeMask: NSEvent.EventTypeMask {
        switch captureType {
        case .move:
            return MouseEventCapture.moveEventTypeMask
        case .click:
            return MouseEventCapture.clickEventTypeMask
        case .cursor:
            return [MouseEventCapture.moveEventTypeMask, MouseEventCapture.clickEventTypeMask]
        }
    }
    
    override func start(completion: ((Result<(), any Error>) -> ())?) {
        guard state == .idle else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: self.eventTypeMask) { [weak self] event in
            self?.queue.async {
                self?.didRecivedEvent(event)
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: self.eventTypeMask, handler: { [weak self] event in
            self?.queue.async {
                self?.didRecivedEvent(event)
            }
            return event
        })
        completion?(.success(()))
    } 
    
    override func stop(completion: ((Result<(), any Error>) -> ())?) {
        guard state != .idle else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        setState(.stopped)
        completion?(.success(()))
    }
    
}

extension MouseEventCapture {
    
    func didRecivedEvent(_ event: NSEvent) {
        let mouseEvent = MouseEvent(with: event, cursor: NSCursor.currentSystem ?? .arrow)
        onCapture?(mouseEvent)
    }
    
}
