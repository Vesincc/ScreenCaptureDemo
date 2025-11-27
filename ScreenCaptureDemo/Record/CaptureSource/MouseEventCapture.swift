//
//  MouseEventCapture.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2025/11/25.
//

import AppKit
import CommonCrypto

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

extension Data {
    func sha256() -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

class MouseEventCapture: CaptureSource<Encodable> {
     
    struct MouseEvent: Codable {
        
        struct CursorAndHash {
            
            lazy var cursorIdDic: [String : String] = {
                var images: [(String, NSImage)] = []
                images.append(contentsOf: universalCursors)
                images.append(contentsOf: definedCursors)
                
                let noDefined = noDefinedCursors
                var result: [String : String] = [:]
                noDefined.forEach({
                    result[$0.1] = $0.0
                })
                images.forEach({
                    if let hash = $0.1.tiffRepresentation?.sha256() {
                        result[hash] = $0.0
                    }
                })
                return result
            }()
            
            var universalCursors: [(String, NSImage)] {
                [
                    ("arrow",NSCursor.arrow.image),
                    ("iBeam",NSCursor.iBeam.image),
                    ("pointingHand",NSCursor.pointingHand.image),
                    ("closedHand",NSCursor.closedHand.image),
                    ("openHand",NSCursor.openHand.image),
                    ("resizeLeft",NSCursor.resizeLeft.image),
                    ("resizeRight",NSCursor.resizeRight.image),
                    ("resizeLeftRight",NSCursor.resizeLeftRight.image),
                    ("resizeUp",NSCursor.resizeUp.image),
                    ("resizeDown",NSCursor.resizeDown.image),
                    ("resizeUpDown",NSCursor.resizeUpDown.image),
                    ("crosshair",NSCursor.crosshair.image),
                    ("disappearingItem",NSCursor.disappearingItem.image),
                    ("operationNotAllowed",NSCursor.operationNotAllowed.image),
                    ("dragLink",NSCursor.dragLink.image),
                    ("dragCopy",NSCursor.dragCopy.image),
                    ("contextualMenu",NSCursor.contextualMenu.image),
                    ("iBeamCursorForVerticalLayout",NSCursor.iBeamCursorForVerticalLayout.image)
                ]
            }
             
            var definedCursors: [(String, NSImage)] {
                if #available(macOS 15, *) {
                    return [
                        ("resizeDiagonal1", NSCursor.frameResize(position: .topLeft, directions: .all).image),
                        ("resizeDiagonal2", NSCursor.frameResize(position: .topRight, directions: .all).image),
                        ("resizeHorizontal",NSCursor.frameResize(position: .left, directions: .all).image),
                        ("resizeVertical", NSCursor.frameResize(position: .top, directions: .all).image),
                        ("resizeTopLeft", NSCursor.frameResize(position: .topLeft, directions: .outward).image),
                        ("resizeBottomRight", NSCursor.frameResize(position: .bottomRight, directions: .outward).image),
                        ("resizeBottomLeft", NSCursor.frameResize(position: .bottomLeft, directions: .outward).image),
                        ("resizeTopRight", NSCursor.frameResize(position: .topRight, directions: .outward).image),
                        ("windowResizeLeft", NSCursor.frameResize(position: .left, directions: .outward).image),
                        ("windowResizeRight", NSCursor.frameResize(position: .right, directions: .outward).image),
                        ("resizeTop", NSCursor.frameResize(position: .top, directions: .outward).image),
                        ("resizeBottom", NSCursor.frameResize(position: .bottom, directions: .outward).image)
                    ]
                } else {
                    return []
                }
            }
            
            var noDefinedCursors: [(String, String)] {
                [
                    ("screenshotwindow", "064d1496f3ca78d32a8b3fd1504d640261b0c8b9ab05d0233efa0ed727510b80"),// 截图
                    ("resizeDiagonal1", "d2f590147853317831e42fd263d7de837a28dc847a130fb6aa956322403b7f13"), // 对角线调整（↖↘）
                    ("resizeDiagonal2", "1f0f420e4e93f85aff6e728be5c0a8545a362536d2cee6b1a5a91609e7fde7e6"), // 对角线调整（↙↗）
                    ("resizeHorizontal", "80a4426c8d02cf450525fe592eee5935fc63b5b43780ac49d24f986e1e6801a6"), // 水平调整（←→）
                    ("resizeVertical", "6da113305022f836216fa4efe4eabcd8af60d3f68d055ff3a6175eadd4a0f584"), // 垂直调整（↑↓）
                    ("resizeTopLeft", "9326d1297ed4423805b50a2fa06f6e9cbaf85d5ecb143880f7fc7e4e2fe4e12d"), //左上(↖)
                    ("resizeBottomRight", "3c009ba2988cc0dc636b55fe5d3c301190a09bbc76f7c390fcb4eff9d314962e"), //右下(↘)
                    ("resizeBottomLeft", "28f47026b1ac99979b8574bab9ad8116917630da5a9daa2898ff939c7c6a397b"), //左下(↙)
                    ("resizeTopRight", "cda0dd9597d5b2a910b854a1d61309beab98f2b29e1ecb6ce9f81902dfc7eac0"), //右上(↗)
                    ("windowResizeLeft", "0b3bf3dea71982cfe4109a26b27853b48148403b78b8669e4e1699f613862530"), //左边(←)
                    ("windowResizeRight", "87d1b0611fb1e0e5abe9d950ce9eaea02ccbf0e39a7b448b899f4704b10fa557"), //右边(→)
                    ("resizeTop", "d47492de52be0149ab400a66cbbadfb8634087db5cd58bde8be3628d81185863"), //上边(↑)
                    ("resizeBottom", "c9e90d22fdb716c3bca5826bf135c17fff34dcf4a11133d82b01811d7f3f656c"), //下边(↓)
                    ("screenshotwindow", "eeb7f22c6809505b9f48ae5f25559bdbf6fe18a5d4741fbe0cc323c1fb050546"),// 15 系统 截图
                    ("screenshotwindow", "87ffa1dbacd854f8f0e44c8817a47ea5ae29a5e7b6e182a559997776d082ca19"),// 26 系统 截图
                ]
            }
        }
        
        static var cursorHash = CursorAndHash()
        
        enum EventType: String, Codable, CaseIterable {
            case mouseMoved
            case mouseDragged
            case mouseDown
            case mouseUp
        }
        
        let type: EventType
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
            type = .init(rawValue: event?.type.mouseType ?? "") ?? .mouseMoved
            x = point.x
            y = point.y
            cursorId = ""
            
            if let hash = cursor.image.tiffRepresentation?.sha256() {
                if let id = MouseEventCapture.MouseEvent.cursorHash.cursorIdDic[hash] {
                    cursorId = id
                } else {
                    cursorId = UUID().uuidString
                }
            }
            
        }
    }
    
    
    static var moveEventTypeMask: NSEvent.EventTypeMask {
        [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
    }
    
    static var clickEventTypeMask: NSEvent.EventTypeMask {
        [.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp]
    }
    
    let queue = DispatchQueue(label: "MouseEventCapture.queue", qos: .userInteractive)
    
    var globalMonitor: Any?
    var localMonitor: Any?
     
    var eventTypeMask: NSEvent.EventTypeMask {
        return [MouseEventCapture.moveEventTypeMask, MouseEventCapture.clickEventTypeMask]
    }
    
    override func start(completion: ((Result<(), any Error>) -> ())?) {
        guard state == .idle else {
            completion?(.failure(ControlStateError.invalid))
            return
        }
        
        setState(.starting)
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
        setState(.running)
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
