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
import MapKit.MKGeoJSONSerialization
import OSLog

class Document: NSPersistentDocument {
    
    var contentViewController: MapViewController!
    
    override class var autosavesInPlace: Bool { return true }
            
    let logger = Logger(subsystem: "org.appel-rockhold.Georg", category: "Document")
        
    
    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! WindowController
        self.addWindowController(windowController)
        
        // Set the view controller's represented object as your document.
        if let contentVC = windowController.contentViewController as? MapViewController {
            let mapViewModel = MapViewModel(context: managedObjectContext!, mapViewController: contentVC)
            contentVC.viewModel = mapViewModel
            contentViewController = contentVC
        }
    }
    
    override func configurePersistentStoreCoordinator(
        for url: URL,
        ofType fileType: String,
        modelConfiguration configuration: String?,
        storeOptions: [String : Any]? = nil
    ) throws {
                
        let myStoreOptions = [
            NSPersistentStoreRemoteChangeNotificationPostOptionKey: true as NSNumber,
            NSPersistentHistoryTrackingKey: true as NSNumber
        ]
        try super.configurePersistentStoreCoordinator(for: url, ofType: fileType, modelConfiguration: configuration, storeOptions: myStoreOptions)
    }
    
    @IBAction
    func importKML(_ sender: Any?) {
        
        guard let docWindow = self.windowControllers.first?.window else {
            return
        }
        guard let _ = managedObjectContext else {
            return
        }
        
        let geojsonFileType = UTType(filenameExtension: "geojson", conformingTo: .json)!
        
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [geojsonFileType]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.beginSheetModal(for: docWindow) { [self] (result) -> Void in
            if result == .OK {
                do {
                    try makeLayer(dataURL: openPanel.url)
                }
                catch {
                    self.logger.debug("attempting to import new layer info from GeoJSON file")
                }
            }
        }
    }
        
    @MainActor
    private func makeLayer(zindex: Int) -> GeoLayer {
        return GeoLayer(context: managedObjectContext!, zindex: zindex)
    }
    
    @MainActor
    private func addObjectToLayer(mkGeoObject: MKGeoJSONObject, 
                                  layer: GeoLayer,
                                  geometryFactory: GeometryFactory) {
        do {
            try layer.add(mkGeoObject: mkGeoObject,
                          geometryFactory: geometryFactory,
                          context: managedObjectContext!)
        }
        catch {
            // TODO: handle error better
            self.logger.debug("could not add shape or feature to layer")
        }
    }
    
    public func makeLayer(dataURL: URL?) throws {
        guard let managedObjectContext = self.managedObjectContext else {
            return
        }
        
        guard let dataURL = dataURL else {
            // TODO: throw something
            return
        }
        let decoder = MKGeoJSONDecoder()
        let geometryFactory = GeometryFactory()
        
        let countOfLayers = (try? managedObjectContext.count(for: GeoLayer.fetchRequest())) ?? 0
                
        Task {
            
            let layer = makeLayer(zindex: countOfLayers)
            do {
                for mkGeoObject in try decoder.decode(try Data(contentsOf: dataURL)) {
                    
                    addObjectToLayer(mkGeoObject: mkGeoObject,
                                     layer: layer,
                                     geometryFactory: geometryFactory)
                }
            }
            catch {
                self.logger.debug("error decoding GeoJSON file")
            }
        }
    }
}
