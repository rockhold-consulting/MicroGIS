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
//  MapViewController.swift
//  Georg
//
//  Created by Michael Rockhold on 8/21/23.
//

import Cocoa
import MapKit

class MapViewController: NSViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    static let geoPointReuseIdentifier = NSStringFromClass(GeoPoint.self)
    static let clusterAnnotationReuseIdentifier = MKMapViewDefaultClusterAnnotationViewReuseIdentifier
        
    let annotationImage = NSImage(systemSymbolName: "mappin.circle", // or bubble.middle.bottom
                                  accessibilityDescription: "Map pin inside a circle")!
    
    let clusterAnnotationImage = NSImage(systemSymbolName: "seal",
                                         accessibilityDescription: "star-like shape")!
    
    var documentContext: NSManagedObjectContext
    var viewModel: MapViewModel
    
    required init?(coder aDecoder: NSCoder, docContext: NSManagedObjectContext) {
        documentContext = docContext
        viewModel = MapViewModel(context: documentContext)
        super.init(coder: aDecoder)
        viewModel.mapViewController = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerMapAnnotationViews()
        viewModel.load()
    }
    
    private func registerMapAnnotationViews() {
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.geoPointReuseIdentifier)
        
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.clusterAnnotationReuseIdentifier)
        
    }

    public func load(overlays optoverlays: [GeoOverlay]?) {
        guard let overlays = optoverlays else { return }
        
        load(geoPoints: overlays.filter { $0.geometry! is GeoPoint } as! [GeoPoint])
        
        load(otherOverlays: overlays.filter { $0.geometry!.conforms(to: MKOverlay.self) })
    }
    
    private func load(geoPoints: [GeoPoint]) {
        guard !geoPoints.isEmpty else { return }
        Task(priority: .background) {
            await MainActor.run {
                self.mapView.addAnnotations(geoPoints)
            }
        }
    }
    
    private func load(otherOverlays: [MKOverlay]) {
        guard !otherOverlays.isEmpty else { return }
        self.mapView.addOverlays(otherOverlays, level: .aboveRoads)
    }
}

extension MapViewController: MKMapViewDelegate {
    
//    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
//    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let geoOverlay = overlay as? GeoOverlay, let info = geoOverlay.geometry as? GeoOverlayShape else {
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
            // not an annotation view we wish to customize yet.
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
