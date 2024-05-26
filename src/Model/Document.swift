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
import OSLog

class Document: NSPersistentDocument {

    override class var autosavesInPlace: Bool { return true }
            
    let logger = Logger(subsystem: "org.appel-rockhold.Georg", category: "Document")

    override var managedObjectModel: NSManagedObjectModel? {
        return (NSApplication.shared.delegate as! AppDelegate).documentObjectModel
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains the main Document window.
        // Creates a view model required by some of the various view controllers embedded in that window's hierarchy,
        // and injects it into the root view controller
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
        windowController.contentViewController?.representedObject = managedObjectContext

        self.addWindowController(windowController)
    }

    @IBAction
    func importFile(_ sender: Any?) {

        guard let docWindow = self.windowControllers.first?.window else {
            return
        }
        guard let _ = managedObjectContext else {
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
            self.importGeoJSON(url: openPanel.url!)
        }
    }

    @IBAction
    func exportToFile(_: AnyObject) {
        // TODO: implement me
    }

    func importGeoJSON(url: URL) {
        guard let moc = self.managedObjectContext else { return }
        let geoObjectCreator = CoreDataGeoObjectCreator(importContext: moc)
        GeorgMKGeoJSONFeatureSource().importLayer(from: url, creator: geoObjectCreator)
    }
}
