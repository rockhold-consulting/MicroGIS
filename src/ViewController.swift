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

class ViewController: NSViewController {
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            updateMapViewCenter()
        }
    }
    
    static let geoPointReuseIdentifier = NSStringFromClass(GeoPointAnnotation.self)
    static let clusterAnnotationReuseIdentifier = MKMapViewDefaultClusterAnnotationViewReuseIdentifier
    
    var mapCenter: MapCenter? = nil
    var fetchedGeoOverlayResultsController: NSFetchedResultsController<GeoOverlay>?
    
    let annotationImage = NSImage(systemSymbolName: "mappin.circle", // or bubble.middle.bottom
                                  accessibilityDescription: "Map pin inside a circle")!
    
    let clusterAnnotationImage = NSImage(systemSymbolName: "seal",
                                         accessibilityDescription: "star-like shape")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerMapAnnotationViews()
        
        if let mv = mapView, let mc = mapCenter {
            mv.setCenter(mc.coordinate, animated: false)
        }
    }
    
    private func registerMapAnnotationViews() {
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.geoPointReuseIdentifier)
        
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.clusterAnnotationReuseIdentifier)
        
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
            
            let overlayReq = GeoOverlay.fetchRequest()
            overlayReq.sortDescriptors = [NSSortDescriptor(key: "feature.layer.zindex", ascending: true)]
            fetchedGeoOverlayResultsController = NSFetchedResultsController(
                fetchRequest: overlayReq,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil)
            fetchedGeoOverlayResultsController?.delegate = self
            
            do {
                try fetchedGeoOverlayResultsController?.performFetch()
                load(overlays: fetchedGeoOverlayResultsController?.fetchedObjects)
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
        
    func load(overlays optoverlays: [GeoOverlay]?) {
        guard let overlays = optoverlays else { return }
        
        load(geoPointAnnotations: overlays.filter { $0.geoInfo! is GeoPointAnnotation } as! [GeoPointAnnotation])
        
        load(otherOverlays: overlays.filter { $0.geoInfo!.conforms(to: MKOverlay.self) })
    }
    
    private func load(geoPointAnnotations gpas: [GeoPointAnnotation]) {
        guard !gpas.isEmpty else { return }
        Task(priority: .background) {
            await MainActor.run {
                self.mapView.addAnnotations(gpas)
            }
        }
    }
    
    private func load(otherOverlays: [MKOverlay]) {
        guard !otherOverlays.isEmpty else { return }
        self.mapView.addOverlays(otherOverlays, level: .aboveRoads)
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        load(overlays: fetchedGeoOverlayResultsController?.fetchedObjects)
    }
}

extension ViewController: MKMapViewDelegate {
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let cntr = mapView.centerCoordinate
        DispatchQueue.main.async() { [self] in
            if let mc = mapCenter {
                mc.coordinate = cntr
            }
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let geoOverlay = overlay as? GeoOverlay, let info = geoOverlay.geoInfo as? GeoOverlayShape else {
            return MKOverlayRenderer(overlay: overlay)
        }
        
        return applyStyle(to: info.makeOverlayRenderer(), for: geoOverlay.feature)
    }
    
    // TODO: this is where the style engine goes :)
    private func applyStyle(to overlayRenderer: MKOverlayRenderer, for feature: GeoFeature?) -> MKOverlayRenderer {
        
        switch overlayRenderer {
        case let multipolygonRenderer as MKMultiPolygonRenderer:
            multipolygonRenderer.fillColor = NSColor.red
            multipolygonRenderer.strokeColor = NSColor.red
            
        case let multipolylineRenderer as MKMultiPolylineRenderer:
            multipolylineRenderer.fillColor = NSColor.blue
            multipolylineRenderer.strokeColor = NSColor.blue
            
        case let polygonRenderer as MKPolygonRenderer:
            polygonRenderer.fillColor = NSColor.yellow
            polygonRenderer.strokeColor = NSColor.yellow

        case let polylineRenderer as MKPolylineRenderer:
            polylineRenderer.fillColor = NSColor.green
            polylineRenderer.strokeColor = NSColor.green

        case let circleRenderer as MKCircleRenderer:
            circleRenderer.fillColor = NSColor.orange
            circleRenderer.strokeColor = NSColor.orange

        case let gradientPolylineRenderer as MKGradientPolylineRenderer:
            gradientPolylineRenderer.fillColor = NSColor.purple // or something
            gradientPolylineRenderer.strokeColor = NSColor.purple // or something

        case let overlayPathRenderer as MKOverlayPathRenderer:
            overlayPathRenderer.fillColor = NSColor.black
            overlayPathRenderer.strokeColor = NSColor.black

        default:
            break
        }
        
        return overlayRenderer
    }
    
    func mapView(_ mapView: MKMapView, 
                 viewFor annotation: MKAnnotation) -> MKAnnotationView? {
                
        switch annotation {
        case let userLocation as MKUserLocation:
            // Make a fast exit if the annotation is the `MKUserLocation`, as it's 
            // not an annotation view we wish to customize.
            return nil
            
        case let geoOverlay as GeoOverlay:
            let annotationView = setupPointAnnotationView(for: geoOverlay, on: mapView)
            annotationView.clusteringIdentifier = "pointcluster" // TODO: this is _very_ tempory
            return annotationView
            
        case let clusterAnnotation as MKClusterAnnotation:
            let annotationView = setupClusterAnnotationView(for: clusterAnnotation, on: mapView)
            return annotationView

        default:
            return nil
        }
    }
    
    private func setupPointAnnotationView(for annotation: GeoOverlay, on mapView: MKMapView) -> MKAnnotationView {
                
        let pointAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: Self.geoPointReuseIdentifier,
                                                                        for: annotation)
        
        //            pointAnnotationView.canShowCallout = true
        
        // Provide the annotation view's image.
        //            let image = #imageLiteral(resourceName: "flag")
        pointAnnotationView.image = self.annotationImage
        
        //            // Provide the left image icon for the annotation.
        //            pointAnnotationView.leftCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "sf_icon"))
        
        // Offset the flag annotation so that the flag pole rests on the map coordinate.
        //            let offset = CGPoint(x: image.size.width / 2, y: -(image.size.height / 2) )
        //            pointAnnotationView.centerOffset = offset
        
        return pointAnnotationView
    }
    
    private func setupClusterAnnotationView(for annotation: MKClusterAnnotation, 
                                            on mapView: MKMapView) -> MKAnnotationView {
        
        let clusterAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: Self.clusterAnnotationReuseIdentifier,
                                                                        for: annotation)
        
        //            pointAnnotationView.canShowCallout = true
        
        // Provide the annotation view's image.
        //            let image = #imageLiteral(resourceName: "flag")
        clusterAnnotationView.image = self.clusterAnnotationImage
        
        //            // Provide the left image icon for the annotation.
        //            pointAnnotationView.leftCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "sf_icon"))
                
        return clusterAnnotationView
    }

}
