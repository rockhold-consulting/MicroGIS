// This file is part of Georg, a macOS/iOS program for displaying and
// editing "geofeatures" on a map.
//
// Copyright (C) 2023  Michael E. Rockhold
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https:www.gnu.org/licenses/>.
//
//  Document.swift
//  Georg
//
//  Created by Michael Rockhold on 8/21/23.
//

import Cocoa
import UniformTypeIdentifiers
import SwiftUI
import OSLog

class Document: NSPersistentDocument {

    override class var autosavesInPlace: Bool { return true }
            
    let logger = Logger(subsystem: "org.appel-rockhold.Georg", category: "Document")

    override var managedObjectModel: NSManagedObjectModel? {
        return (NSApplication.shared.delegate as! AppDelegate).documentObjectModel
    }

    override func makeWindowControllers() {
        let f = (NSScreen.main?.visibleFrame)!
        let window = NSWindow(
            contentRect: f,
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.contentViewController = HostingController(rootView: DocumentView().environment(\.managedObjectContext, self.managedObjectContext!), frame: f)
        let windowController = NSWindowController(window: window)
        self.addWindowController(windowController)
        self.gratuitousAutosave()
    }

    func gratuitousAutosave() {
        self.updateChangeCount(.changeDone)
        self.autosave(withDelegate: self,
                      didAutosave: #selector(document(_:didAutosave:contextInfo:)),
                      contextInfo: nil)
    }
    @objc func document(_ document: NSDocument,
                  didAutosave didAutosaveSuccessfully: Bool,
                  contextInfo: UnsafeMutableRawPointer?) {
        self.updateChangeCount(.changeUndone)
    }


    @IBAction
    func importFile(_ sender: Any?) {

        guard self.windowControllers.first?.window != nil,
              managedObjectContext != nil else {
            return
        }
        
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType(filenameExtension: "geojson", conformingTo: .json)!]
        openPanel.message = NSLocalizedString("Choose File to Import Message", comment: "")
        openPanel.prompt = NSLocalizedString("Import", comment: "")

        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true

        openPanel.begin { [self] (response) in
            guard response == NSApplication.ModalResponse.OK else { return }
            self.importFeaturesFile(url: openPanel.url!)
        }
    }

    @IBAction
    func exportToFile(_: AnyObject) {
        // TODO: implement me
    }

    func importFeaturesFile(url: URL) {
        guard let moc = self.managedObjectContext else { return }
        let geoObjectCreator = CoreDataGeoObjectCreator(importContext: moc)

        self.gratuitousAutosave()

        let ext = url.pathExtension
        if ext.uppercased() == "GEOJSON" {
            GeorgMKGeoJSONFeatureSource().importLayer(from: url, creator: geoObjectCreator)
        }
    }
}
