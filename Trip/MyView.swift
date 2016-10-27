//
//  MyView.swift
//  Trip
//
//  Created by Martin Kautz on 27.10.16.
//
//

import Cocoa

class MyView: NSView {

    var filePath: String?
    let expectedExt = "gpx"

    required init?(coder: NSCoder) {
        super.init(coder: coder)


        register(forDraggedTypes: [NSFilenamesPboardType, NSURLPboardType])
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if let pasteboard = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
            if let path = pasteboard[0] as? String {
                let ext = NSURL(fileURLWithPath: path).pathExtension
                if ext == expectedExt {
                    return .copy
                }
            }
        }
        return []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
    }

    override func draggingEnded(_ sender: NSDraggingInfo?) {
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let pasteboard = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
            if let path = pasteboard[0] as? String {
                self.filePath = path
                //GET YOUR FILE PATH !!

                Swift.print("filePath: \(filePath)")
                if let winController = self.window?.windowController as? WindowController {
                    winController.foo(path: self.filePath!)
                }
                return true
            }
        }
        return false
    }
}
