//
//  AppWindowControllerManager.swift
//  ScreenCaptureDemo
//
//  Created by HanQi on 2026/1/6.
//

import AppKit

class AppWindowCoordinator {
    
    static let shared = AppWindowCoordinator()
    
    private var controllers: [NSWindowController] = []
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose(_ :)), name: NSWindow.willCloseNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
     
    @objc func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
            return
        }
        guard let controller = controllers.first(where: { $0.window == window }) else {
            return
        }
        controllers.removeAll(where: { $0 == controller })
    }
    
}

extension AppWindowCoordinator {
    
    func add(_ controller: NSWindowController?) {
        guard let controller = controller else {
            return
        }
        if !controllers.contains(where: { $0 == controller }) {
            controllers.append(controller)
        } else {
            controllers.removeAll(where: { $0 == controller })
            controllers.append(controller)
        }
    }
    
    func show(_ controller: NSWindowController?) {
        guard let controller = controller else {
            return
        }
        add(controller)
        controller.showWindow(nil)
    }
    
    func close(_ controller: NSWindowController?) {
        guard let controller = controller else {
            return
        }
        controllers.removeAll(where: { $0 == controller })
        controller.close()
    }
       
    func activate(_ controller: NSWindowController?, isScene: Bool = true) {
        guard let controller = controller else {
            return
        }
        show(controller)
        if isScene {
            controllers.filter({ $0 != controller }).forEach({
                $0.window?.resignKey()
                $0.window?.orderOut(nil)
            })
        }
    }
    
    func deactivateAndOrderOut(_ controller: NSWindowController?) {
        guard let controller = controller else {
            return
        }
        guard controllers.contains(where: { $0 == controller }) else {
            return
        }
        controller.window?.resignKey()
        controller.window?.orderOut(nil)
        if let top = controllers.last(where: { $0 != controller }) {
            show(top)
        }
    }
}
