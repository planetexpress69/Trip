//
//  MyView.swift
//  Trip
//
//  Created by Martin Kautz on 27.10.16.
//
//

import Cocoa

class MyView: NSView {

    let expectedExt = ["gpx", "GPX"]


    required init?(coder: NSCoder) {
        super.init(coder: coder)
        register(forDraggedTypes: [NSFilenamesPboardType, NSURLPboardType])
    }


    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }


    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard
            let pasteboard = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray,
            let path = pasteboard[0] as? String,
            let ext = NSURL(fileURLWithPath: path).pathExtension else {
                return []
        }
        if expectedExt.contains(ext) {
            return .copy
        }
        return []
    }


    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard
            let pasteboard = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray,
            let path = pasteboard[0] as? String,
            let winController = self.window?.windowController as? WindowController else {
                return false
        }
        winController.foo(path: path)
        return true
    }

}
