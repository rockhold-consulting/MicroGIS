//
//  MapViewModel.swift
//  Georg
//
//  Created by Michael Rockhold on 12/17/23.
//

import Foundation
import AppKit
import CoreData
import Combine
import MapKit

class MapViewModel: NSObject {

    typealias IDSet = Set<NSManagedObjectID>

    weak var mapViewController: MapViewController?
    let treeController: NSTreeController
    var selectedGeometries = IDSet() {
        willSet {
            previousSelectedGeometries = selectedGeometries
        }
        didSet {
            let newlySelected = selectedGeometries.subtracting(previousSelectedGeometries)
            let newlyDeselected = previousSelectedGeometries.subtracting(selectedGeometries)
            let toChange = newlySelected.union(newlyDeselected)
            Task {
                await mapViewController?.rerenderSelection(changeSet: toChange)
            }
        }
    }
    var previousSelectedGeometries = IDSet()
    var selectionChangedCancellable: Cancellable? = nil
    var arrangedObjectsCancellable: Cancellable? = nil

    init(treeController t: NSTreeController, mapViewController mvc: MapViewController) {
        mapViewController = mvc
        treeController = t
        super.init()

        arrangedObjectsCancellable = treeController.publisher(for: \.arrangedObjects)
            .sink() { [self] arrangedObjectsProxy in
                self.mapViewController?.reload()
            }

        // Listen to the treeController's selection change so you inform clients to react to selection changes.
        selectionChangedCancellable = treeController.publisher(for: \.selectedNodes)
            .sink() { [self] selectedNodes in
                let newSelection = selectedNodes.compactMap { treeNode in
                    treeNode.representedObject as? NSManagedObject
                }
                .flatMap { object in
                    switch object {
                    case let geometry as Geometry:
                        return [geometry.objectID]
                    default: // ignore
                        return []
                    }
                }

                Task {
                    self.selectedGeometries =  IDSet(newSelection)
                }
            }
    }

    deinit {
        arrangedObjectsCancellable?.cancel()
        selectionChangedCancellable?.cancel()
    }

    func isIDSelected(_ objID: NSManagedObjectID) -> Bool {
        return selectedGeometries.contains(objID)
    }
    
    func clearSelection() {
        treeController.removeSelectionIndexPaths(treeController.selectionIndexPaths)
    }

    private func findTreeNode(for id: NSManagedObjectID, under node: NSTreeNode) -> NSTreeNode? {

        if (node.representedObject as? NSManagedObject)?.objectID == id {
            return node
        } else {
            guard let kids = node.children else { return nil }
            for child in kids {
                if let n = findTreeNode(for: id, under: child) {
                    return n
                }
            }
        }
        return nil
    }

    func select(_ objID: NSManagedObjectID) {

        if let node = findTreeNode(for: objID, under: treeController.arrangedObjects) {
            treeController.addSelectionIndexPaths([node.indexPath])
        }
    }

    func deselect(_ objID: NSManagedObjectID) {
        if let node = findTreeNode(for: objID, under: treeController.arrangedObjects) {
            treeController.removeSelectionIndexPaths([node.indexPath])
        }
    }

    func geometry(with objID: NSManagedObjectID) -> Geometry {
        return treeController.managedObjectContext?.object(with: objID) as! Geometry
    }

    func reload(reloadViewControllerFn: ([MKAnnotation], [MKOverlay], [MKMapPoint], MKMapRect) ->Void) {

        var annotations = [MKAnnotation]()
        var overlays = [MKOverlay]()

        var bigbox = MKMapRect.null
        var centroids = [MKMapPoint]()

        func add(geometry: Geometry) {
            bigbox = bigbox.union(geometry.betterBox)
            centroids.append(MKMapPoint(geometry.coordinate))

            let gp = GeometryProxy(geometry: geometry)
            if geometry.wrapped?.shape is GeoPoint {
                annotations.append(gp)
            } else {
                overlays.append(gp)
            }
        }

        func add(geometries: [Geometry]?, feature: Feature? = nil) {
            geometries?.forEach { g in
                add(geometry: g)
            }
        }

        print("arrangeObjects \(self.treeController.arrangedObjects)")
        self.treeController.arrangedObjects.children?.forEach { node in

            guard let layer = node.representedObject as? Layer,
                  let kids = layer.kidArray else { return }

            for layerChild in kids {
                switch layerChild {
                case let f as Feature:
                    guard let featureKids = f.kidArray else { return }
                    add(geometries: featureKids as? [Geometry])
                    break

                case let g as Geometry:
                    add(geometry: g)
                    break

                default:
                    break
                }
            }
        }

        reloadViewControllerFn(annotations, overlays, centroids, bigbox)
    }

    //    public func load() {
    //
    //        do {
    //            try fetchedModelObjectsResultsController.performFetch()
    //            mapViewController?.load(overlays: fetchedModelObjectsResultsController.fetchedObjects)
    //        }
    //        catch {
    //            fatalError("Failed to fetch entities: \(error)")
    //        }
    //    }
}

//extension MapViewModel: NSFetchedResultsControllerDelegate {
//
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        mapViewController?.load(overlays: fetchedModelObjectsResultsController.fetchedObjects)
//    }
//}
