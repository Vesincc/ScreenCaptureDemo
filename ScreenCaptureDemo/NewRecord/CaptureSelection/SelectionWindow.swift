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
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) else {
            fatalError("No screen found under mouse")
        }
        let windows = sharingWindows()
        print("windows: \(windows)")
        
        let hoveredWindow = windows
            .first { $0.frame.contains(mouseLocation) }
         
        if overlay.superview == nil {
            contentView?.addSubview(overlay)
        }
        
        if let window = hoveredWindow {
            overlay.frame = convertFromScreen(window.frame)
        }
    }
    
    func sharingWindows() -> [SharingWindow] {
        guard let windowInfoList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return []
        }
        let myPID = NSRunningApplication.current.processIdentifier
        let results: [SharingWindow] = windowInfoList.compactMap { dict in
            guard let onscreen = dict[kCGWindowIsOnscreen as String] as? Bool, onscreen else {
                return nil
            }
            
            if let pid = dict[kCGWindowOwnerPID as String] as? pid_t,
               pid == myPID {
                return nil
            }
            
            if let layer = dict[kCGWindowLayer as String] as? Int, layer != 0 {
                return nil
            }
            
            if let sharing = dict[kCGWindowSharingState as String] as? Int,
               sharing < 1 {
                return nil
            }
            
            guard let frame = cgWindowFrame(from: dict) else {
                return nil
            }
            
            guard let windowID = dict[kCGWindowNumber as String] as? CGWindowID else {
                return nil
            }
            
            let pid = dict[kCGWindowOwnerPID as String] as? pid_t ?? 0
            let ownerName = dict[kCGWindowOwnerName as String] as? String ?? ""
            let title = dict[kCGWindowName as String] as? String
            
            let app = NSRunningApplication(processIdentifier: pid)
            
            return SharingWindow(
                windowID: windowID,
                frame: frame,
                ownerPID: pid,
                ownerName: ownerName,
                ownerIcon: app?.icon,
                title: title
            )
        }
        return results
    }
    
    private func cgWindowFrame(from dict: [String: Any]) -> CGRect? {
        guard let bounds = dict[kCGWindowBounds as String] as? [String: Any],
              let x = bounds["X"] as? CGFloat,
              let y = bounds["Y"] as? CGFloat,
              let w = bounds["Width"] as? CGFloat,
              let h = bounds["Height"] as? CGFloat else {
            return nil
        }
        return CGRect(x: x, y: y, width: w, height: h)
    }
    
}

struct SharingWindow {
    let windowID: CGWindowID
    let frame: CGRect
    let ownerPID: pid_t
    let ownerName: String
    let ownerIcon: NSImage?
    let title: String?
}
