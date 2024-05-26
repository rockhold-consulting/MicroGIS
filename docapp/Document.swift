//
//  Document.swift
//  docapp
//
//  Created by Michael Rockhold on 5/25/24.
//

import Cocoa

class Document: NSPersistentDocument {

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        let windowController = NSWindowController(windowNibName: NSNib.Name("Document"))
//        windowController.contentViewController?.representedObject = managedObjectContext

        self.addWindowController(windowController)
    }

}
