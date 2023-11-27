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
//  ViewController.swift
//  Georg
//
//  Created by Michael Rockhold on 8/21/23.
//

import Cocoa
import MapKit

protocol GeoInfoOwner {
    var geoInfo: GeoObject? { get }
}

extension GeoLayerAnnotation: GeoInfoOwner {}
extension GeoLayerOverlay: GeoInfoOwner {}
extension GeoFeatureAnnotation: GeoInfoOwner {}
extension GeoFeatureOverlay: GeoInfoOwner {}

class ViewController: NSViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            updateMapViewCenter()
        }
    }
    
    var mapCenter: MapCenter? = nil
    var fetchedFeatureOverlayResultsController: NSFetchedResultsController<GeoFeatureOverlay>?
            
    override func viewDidLoad() {
        super.viewDidLoad()

        if let mv = mapView, let mc = mapCenter {
            mv.setCenter(mc.coordinate, animated: false)
        }
    }

    override var representedObject: Any? {
        willSet {
            if representedObject != nil { return }
            guard let moc = newValue as? NSManagedObjectContext else { return }
            guard let result = try? moc.execute(MapCenter.fetchRequest()) as? NSAsynchronousFetchResult<MapCenter> else { return }
            guard let countOfContents = result.finalResult?.count else { return }
            
            if countOfContents == 0, let mc = (NSEntityDescription.insertNewObject(forEntityName: "MapCenter", into: moc) as? MapCenter) {
                
                mc.coordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
                mapCenter = mc
                updateMapViewCenter()
            }
        }
        didSet {
            guard let context = representedObject as? NSManagedObjectContext else {
                return
            }
            if let result = try? context.execute(MapCenter.fetchRequest()) as? NSAsynchronousFetchResult<MapCenter>, let mc = result.finalResult?[0] {
                mapCenter = mc
                updateMapViewCenter()
            }
            
            let req = GeoFeatureOverlay.fetchRequest()
            req.sortDescriptors = [NSSortDescriptor(key: "owner.owner.zindex", ascending: true)]
            fetchedFeatureOverlayResultsController = NSFetchedResultsController(
                fetchRequest: req,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil)
            fetchedFeatureOverlayResultsController?.delegate = self
            do {
                try fetchedFeatureOverlayResultsController?.performFetch()
                loadOverlays(overlays: fetchedFeatureOverlayResultsController?.fetchedObjects)
            }
            catch {
                fatalError("Failed to fetch entities: \(error)")
            }
        }
    }
    
    private func updateMapViewCenter() {
        DispatchQueue.main.async() { [self] in
            if let mv = mapView, let mc = mapCenter {
                mv.setCenter(mc.coordinate, animated: false)
            }
        }
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let cntr = mapView.centerCoordinate
        DispatchQueue.main.async() { [self] in
            if let mc = mapCenter {
                mc.coordinate = cntr
            }
        }
    }
        
    func loadOverlays(overlays optoverlays: [GeoFeatureOverlay]?) {
        guard let overlays = optoverlays else {
            return
        }
        self.mapView.addOverlays(overlays)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        loadOverlays(overlays: fetchedFeatureOverlayResultsController?.fetchedObjects)
    }
    
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, 
//                    didChange sectionInfo: NSFetchedResultsSectionInfo,
//                    atSectionIndex sectionIndex: Int,
//                    for type: NSFetchedResultsChangeType) {
//        print("controller.didChange.atSectionIndex.for")
//    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let infoOwner = overlay as? GeoInfoOwner else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let info = infoOwner.geoInfo!
        
        switch info {
        case let multipolygon as GeoMultiPolygon:
            let renderer = MKMultiPolygonRenderer(multiPolygon: multipolygon.makeMKMultiPolygon())
            renderer.fillColor = NSColor.red
            return renderer
            
        case let multipolyline as GeoMultiPolyline:
            let renderer = MKMultiPolylineRenderer(multiPolyline: multipolyline.makeMKMultiPolyline())
            renderer.fillColor = NSColor.blue
            return renderer
            
        default:
            return MKOverlayRenderer(overlay: overlay)
        }
    }
        
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        print("viewForAnnotation")
        return nil
//        let annotationObj = annotation as! NSManagedObject
//        
//        return MKAnnotationView(annotation: annotation, reuseIdentifier: anno)
    }
    
}

