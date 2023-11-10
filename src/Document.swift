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

class Document: NSPersistentDocument {

    var contentViewController: ViewController!
    
    override class var autosavesInPlace: Bool { return true }
        
    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! WindowController
        self.addWindowController(windowController)
        
        // Set the view controller's represented object as your document.
        if let contentVC = windowController.contentViewController as? ViewController {
            contentVC.representedObject = managedObjectContext
            contentViewController = contentVC
        }
    }

    override func configurePersistentStoreCoordinator(
        for url: URL,
        ofType fileType: String,
        modelConfiguration configuration: String?,
        storeOptions: [String : Any]? = nil
    ) throws {
        try super.configurePersistentStoreCoordinator(for: url, ofType: fileType, modelConfiguration: configuration, storeOptions: storeOptions)
    }
    
    @IBAction
    func importKML(_ sender: Any?) {
        
        guard let docWindow = self.windowControllers.first?.window else {
            return
        }
        guard let ctx = managedObjectContext else {
            return
        }
        
        let geojsonFileType = UTType(filenameExtension: "geojson", conformingTo: .json)!
        
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [geojsonFileType]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.beginSheetModal(for: docWindow) { (result) -> Void in
            if result == .OK {
                do {
                    try GeorgLayer.makeLayer(dataURL: openPanel.url,
                                             context: ctx)
                }
                catch {
                    Swift.print("ERROR")
                }
            }
        }
    }
}
