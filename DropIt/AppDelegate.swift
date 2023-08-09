//
//  AppDelegate.swift
//  DropIt
//
//  Created by macuser on 8/9/23.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let windowSize = CGSize(width: 80, height: 80)
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let windowOrigin = NSPoint(x: (screenFrame.size.width - windowSize.width) / 2, y: screenFrame.maxY - windowSize.height)
        
        let windowRect = NSRect(origin: windowOrigin, size: windowSize)
        
        window = NSWindow(contentRect: windowRect, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .floating
        
        let contentView = FloatingView(frame: window.contentView!.bounds)
        window.contentView?.addSubview(contentView)
        
        window.makeKeyAndOrderFront(nil)
    }
}

class FloatingView: NSView {
    private var draggedFiles: [URL] = []
    private var initialLocation: NSPoint = NSPoint.zero
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOpacity = 0.5
        self.layer?.shadowOffset = CGSize(width: 0, height: -5)
        self.layer?.shadowRadius = 5
        self.layer?.cornerRadius = 15
        
        let imageView = NSImageView(image: NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil)!)
        imageView.contentTintColor = NSColor.green
        imageView.frame = NSRect(x: 10, y: 20, width: 100, height: 80)
        self.addSubview(imageView)
    
        self.registerForDraggedTypes([.fileURL])
    }
    
    override func mouseDragged(with event: NSEvent) {
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        var newOrigin = self.window?.frame.origin ?? NSPoint.zero
        
        let newLocation = NSPoint(x: newOrigin.x + (event.locationInWindow.x - initialLocation.x),
                                  y: newOrigin.y + (event.locationInWindow.y - initialLocation.y))
        
        // Make sure the icon stays within the screen boundaries
        newOrigin.x = max(0, min(screenFrame.size.width - frame.size.width, newLocation.x))
        newOrigin.y = max(0, min(screenFrame.size.height - frame.size.height, newLocation.y))
        
        self.window?.setFrameOrigin(newOrigin)
    }
    
    override func mouseDown(with event: NSEvent) {
    initialLocation = event.locationInWindow
        if event.clickCount == 2 {
            openDocuments()
        }
    }

    private func openDocuments() {
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            NSWorkspace.shared.open(documentsURL)
        }
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if sender.draggingSource as? FloatingView != self {
            return .copy
        }
        return []
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("Dragging...")
        guard case let pasteboard = sender.draggingPasteboard,
              let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL]
        else {
            return false
        }
        draggedFiles = fileURLs
        
        for fileURL in fileURLs {
            moveFileToDocuments(fileURL: fileURL)
        }
        
        return true
    }
    
    private func moveFileToDocuments(fileURL: URL) {
        do {
            if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let destinationURL = documentsURL.appendingPathComponent(fileURL.lastPathComponent)
                try FileManager.default.moveItem(at: fileURL, to: destinationURL)
                NSSound(named: NSSound.Name("Pop"))?.play() // Play a sound when a file is dropped
            }
        } catch {
            print("Error moving file: \(error)")
        }
    }
}

