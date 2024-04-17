//
//  MapViewModel.swift
//  Georg
//
//  Created by Michael Rockhold on 12/17/23.
//

import Foundation
import CoreData

class MapViewModel: NSObject {
    let context: NSManagedObjectContext
    weak var mapViewController: MapViewController? = nil
    var fetchedGeoOverlayResultsController: NSFetchedResultsController<GeoOverlay>

    init(context: NSManagedObjectContext) {
        self.context = context
        
        let overlayReq = GeoOverlay.fetchRequest()
        overlayReq.sortDescriptors = [NSSortDescriptor(key: "feature.layer.zindex", ascending: true)]
        fetchedGeoOverlayResultsController = NSFetchedResultsController(
            fetchRequest: overlayReq,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        super.init()
        fetchedGeoOverlayResultsController.delegate = self
    }
    
    public func load() {
        
        do {
            try fetchedGeoOverlayResultsController.performFetch()
            mapViewController?.load(overlays: fetchedGeoOverlayResultsController.fetchedObjects)
        }
        catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }
}

extension MapViewModel: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        mapViewController?.load(overlays: fetchedGeoOverlayResultsController.fetchedObjects)
    }
}
