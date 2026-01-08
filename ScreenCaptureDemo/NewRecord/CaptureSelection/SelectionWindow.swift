//
//  SelectionWindow.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2026/1/6.
//

import AppKit
import ConeMacKit

class SelectionWindow: NSPanel {
     
    var mode: CaptureSelectionContext.Mode = .screen
    var monitor: Any?
    var overlay: SelectionOverlayView = SelectionOverlayView()
     
    convenience init(mode: CaptureSelectionContext.Mode) {
        let mouseLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) else {
            fatalError("No screen found under mouse")
        }
        let frame = screen.frame
        self.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false, screen: screen)
        self.mode = mode
        
        isOpaque = false
        backgroundColor = .clear
        level = .statusBar
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ignoresMouseEvents = false
        let view = NSView()
        view.wantsLayer = true
        contentView = view
     
        updateOverlay(mouseLocation: mouseLocation)
     
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved], handler: { [weak self] event in
            let mouseLocation = NSEvent.mouseLocation
            self?.updateOverlay(mouseLocation: mouseLocation)
            return event
        })
    }
    
    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
     
    
    func updateOverlay(mouseLocation: CGPoint) {
        let windows = sharingWindows(at: mouseLocation)
         
        if overlay.superview == nil {
            contentView?.addSubview(overlay)
        }
        
        if let window = windows.first {
            overlay.frame = convertFromScreen(window.frame)
        }
    }
    
    func sharingWindows(at mouseLocation: CGPoint) -> [SharingWindow] {
        guard let windowInfoList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        let myPID = NSRunningApplication.current.processIdentifier
        let results: [SharingWindow] = windowInfoList.compactMap { dict in
            guard let pid = dict[kCGWindowOwnerPID as String] as? pid_t,
                  let windowRect = getWindowRect(from: dict),
                  let appName = dict[kCGWindowOwnerName as String] as? String,
                  let windowId = dict[kCGWindowNumber as String] as? CGWindowID,
                  let layer = dict[kCGWindowLayer as String] as? Int else {
                return nil
            }
            
            /// 排除系统窗口
            if layer != 0 {
                return nil
            }
            
            guard pid != myPID else {
                return nil
            }
             
            let windowName = dict[kCGWindowName as String] as? String
            
            let mainDisplayBounds = CGDisplayBounds(CGMainDisplayID())
            let windowFrame = CGRect(origin: CGPoint(x: windowRect.origin.x, y: mainDisplayBounds.height - windowRect.maxY), size: windowRect.size)
                   
            let app = NSRunningApplication(processIdentifier: pid)
            return SharingWindow(windowId: windowId, windowName: windowName, frame: windowFrame, pid: pid, appName: appName, appIcon: app?.icon)
        }
        return results.filter({ $0.frame.contains(mouseLocation) })
    }
    
    private func getWindowRect(from dict: [String: Any]) -> CGRect? {
        guard let bounds = dict[kCGWindowBounds as String] as? [String: Any],
              let x = bounds["X"] as? NSNumber,
              let y = bounds["Y"] as? NSNumber,
              let w = bounds["Width"] as? NSNumber,
              let h = bounds["Height"] as? NSNumber else {
            return nil
        }
        
        return CGRect(
            x: x.doubleValue,
            y: y.doubleValue,
            width: w.doubleValue,
            height: h.doubleValue
        )
    }
    
}

struct SharingWindow {
    let windowId: CGWindowID
    let windowName: String?
    let frame: CGRect
    
    let pid: pid_t
    let appName: String
    let appIcon: NSImage?
}
