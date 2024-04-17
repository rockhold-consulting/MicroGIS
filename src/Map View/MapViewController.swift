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
import Combine

class MapViewController: NSViewController {
    
    @IBOutlet weak var mapView: MKMapView!

    /**
     A template URL for map tiles from the National Hydrography Dataset of the United States Geological Survey.
     These map tiles place an emphasis on rivers and bodies of water. These tiles contain an alpha channel, allowing you to place them
     over other map tiles. For example, when placing over shaded topographic relief map tiles, the relationship between
     valleys and rivers is visible.

     More information on this tile set is available at `https://basemap.nationalmap.gov/arcgis/rest/services/USGSHydroCached/MapServer/`.
     */
    private static let HydrographyTilePathTemplate = "https://basemap.nationalmap.gov/arcgis/rest/services/USGSHydroCached/MapServer/WMTS/tile/1.0.0/USGSHydroCached/default/default028mm/{z}/{y}/{x}"

    /**
     A template URL for map tiles showing shaded topographic relief from The National Map of the United States Geological Survey.
     These map tiles place an emphasis on terrain, and highlight the differences between plains and mountains.

     More information on this tile set is available at `https://basemap.nationalmap.gov/arcgis/rest/services/USGSShadedReliefOnly/MapServer/`.
     */
    private static let ShadedReliefTilePathTemplate = "https://basemap.nationalmap.gov/arcgis/rest/services/USGSShadedReliefOnly/MapServer/WMTS/tile/1.0.0/USGSShadedReliefOnly/default/default028mm/{z}/{y}/{x}"

    var reliefTileOverlay: CustomLoadingTileOverlay!

    static let geoPointReuseIdentifier = "\(NSStringFromClass(Geometry.self)).GeoPointReuseIdentifier"
    static let clusterAnnotationReuseIdentifier = MKMapViewDefaultClusterAnnotationViewReuseIdentifier

    let annotationImage = NSImage(systemSymbolName: "mappin.circle", // or bubble.middle.bottom
                                  accessibilityDescription: "Map pin inside a circle")!

    let clusterAnnotationImage = NSImage(systemSymbolName: "seal",
                                         accessibilityDescription: "star-like shape")!

    var selectionChangedCancellable: Cancellable? = nil

    var selectedNodes: [NSTreeNode]? = nil

    var commandWasDown: Bool = false

    override var representedObject: Any? {
        didSet {
            outlineViewModelDidLoad()
        }
    }

    var content: [Layer]? {
        didSet {
            print("got content")
        }
    }

    var selectionIndexPaths: [IndexPath]? = nil {
        didSet {
            print("got selectionIndexPaths")
        }
    }

    func outlineViewModelDidLoad() {
        guard let ovm = outlineViewModel else {
            // TODO: do we need to 'unbind'  and 'unsetup'?
            return
        }

        self.bind(.content,
                to: ovm.treeController,
                withKeyPath: "arrangedObjects",
                options:[.raisesForNotApplicableKeys: true])

        self.bind(.selectionIndexPaths,
                to: ovm.treeController,
                withKeyPath: "selectionIndexPaths",
                options:[.raisesForNotApplicableKeys: true])

        // Listen to the treeController's selection change so you inform clients to react to selection changes.
        // Examine the current selection and adjust the contents and focus of the map.
        selectionChangedCancellable = ovm.treeController.publisher(for: \.selectedNodes)
            .sink() { [self] selectedNodes in

                print("selectedNodes \(selectedNodes)")
                self.selectedNodes = selectedNodes
            }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Self.exposeBinding(.content)
        Self.exposeBinding(.selectionIndexPaths)
        registerMapAnnotationViews(self.mapView)

        let gr = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        gr.delegate = self
        mapView.addGestureRecognizer(gr)

        guard let mv = mapView else { return }

        if #available(macOS 13.0, *) {
            mv.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .realistic,
                                                                   emphasisStyle: .muted)
        } else {
            // Fallback on earlier versions
        }
        mv.isPitchEnabled = true
        mv.showsPitchControl = true
//            mv.pitchButtonVisibility = .visible
        mv.isZoomEnabled = true
        mv.showsZoomControls = true
        mv.isRotateEnabled = true
        mv.showsCompass = true

        reliefTileOverlay = CustomLoadingTileOverlay(urlTemplate: Self.ShadedReliefTilePathTemplate)
        reliefTileOverlay.canReplaceMapContent = true
        mv.addOverlay(reliefTileOverlay)
    }

    private func registerMapAnnotationViews(_ mv: MKMapView) {
        mv.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.geoPointReuseIdentifier)
        mv.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.clusterAnnotationReuseIdentifier)
    }
}

extension MapViewController: MKMapViewDelegate, NSGestureRecognizerDelegate {

    private func setupPointAnnotationView(for annotation: Geometry, on mapView: MKMapView) -> MKAnnotationView {

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


    @MainActor
    private func addToView(annotations: [MKAnnotation],
                           overlays: [MKOverlay],
                           centroids: [MKMapPoint],
                           visibleRect: MKMapRect) async {

        guard let view = mapView else { return }

        view.removeAnnotations(view.annotations)
        view.overlays.forEach { overlay in
            if !(overlay is CustomLoadingTileOverlay) {
                view.removeOverlay(overlay)
            }
        }
//        view.removeOverlays(view.overlays)

        if !annotations.isEmpty {
            view.addAnnotations(annotations)
        }
        if !overlays.isEmpty {
            view.addOverlays(overlays, level: .aboveRoads)
        }

        let currentRect = view.visibleMapRect
        let containsAll = centroids.allSatisfy { p in currentRect.contains(p) }

//        if containsAll && view.region.span.longitudeDelta < 4.0 {
//            // don't reset the view, you can already see the new coordinate
//            return
//        }
        //        view.visibleMapRect = visibleRect
    }

    func reload() {

        var annotations = [MKAnnotation]()
        var overlays = [MKOverlay]()

        var bigbox = MKMapRect.null
        var centroids = [MKMapPoint]()

        func add(geometry: Geometry) {
            bigbox = bigbox.union(geometry.betterBox)
            centroids.append(MKMapPoint(geometry.coordinate))

            if geometry.shape is GeoPoint {
                annotations.append(geometry)
            } else {
                overlays.append(geometry)
            }
        }

        func add(geometries: [Geometry]?, feature: Feature? = nil) {
            geometries?.forEach { g in
                add(geometry: g)
            }
        }

        for layer in self.content ?? [] {
            guard let kids = layer.children?.array else { continue }
            for layerChild in kids {
                switch layerChild {
                case let f as Feature:
                    guard let featureKids = f.children?.array else { continue }
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

        bigbox = bigbox.insetBy(dx: -10000, dy: -10000)

        // TODO: Here's something ugly I can't figure out
        let ays = annotations
        let ohs = overlays
        let cees = centroids
        let vr = bigbox
        Task {
            await self.addToView(annotations: ays,
                                 overlays: ohs,
                                 centroids: cees,
                                 visibleRect:vr)
        }

    }

    @MainActor
    @objc func gestureRecognizer(
        _ gestureRecognizer: NSGestureRecognizer,
        shouldAttemptToRecognizeWith event: NSEvent
    ) -> Bool {

        commandWasDown = event.modifierFlags.contains(.command)
        return true
    }

    @objc func handleClick(gestureRecognizer: NSGestureRecognizer) {

        let loc = gestureRecognizer.location(in: mapView)

        guard let mapPoint = mapView?.pointToMapPoint(loc) else { return }

        // Let's do this the naively stupid way first
        // Given a MapPoint, find the overlay the user has clicked on.
        // For each geometry, create the appropriate overlay renderer,
        // and then use that to generate the Path. For polylines, we go
        // further and create the path that outlines a wide stroke along
        // that path.
        // Finally, use cgpath operations to determine whether this point is
        // inside that generated path.
        mapView?.overlays.forEach { overlay in

            guard let geometry = overlay as? Geometry, let renderer = geometry.makeRenderer() else { return }

            let viewPoint = renderer.point(for: mapPoint)

            guard var path = renderer.path else { return }

            // If the geometry is a LineString, turn the path from a sequence of line segments
            // into a thin polygon
            if geometry.shape is GeoPolyline || geometry.shape is GeoMultiPolyline {
                path = path.copy(strokingWithWidth: 500, lineCap: .round, lineJoin: .round, miterLimit: 0)
            }

            if path.contains(viewPoint) {
                if let f = geometry.parent {
                    objectTapped(featureID: f.id, continueSelection: commandWasDown)
                }
            }

        }
    }

    func objectTapped(featureID: ObjectIdentifier, continueSelection: Bool = false) {
        // TODO: implement me
//        if selection.contains(featureID) {
//            selection.remove(featureID)
//        } else {
//
//            if !continueSelection {
//                selection.removeAll()
//            }
//            selection.insert(featureID)
//        }
    }

    func isSelected(_ objectID: ObjectIdentifier) -> Bool {
        // TODO: implement selection
        return false

        //return selection.contains(objectID)
    }

    //    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
    //    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        switch overlay {
        case let geometry as Geometry:
            return applyStyle(geometry.makeRenderer(), for: geometry) ?? MKOverlayRenderer(overlay: overlay)

        case let overlay as MKTileOverlay:
            return MKTileOverlayRenderer(tileOverlay: overlay)

        default:
            return MKOverlayRenderer(overlay: overlay)
        }
    }

    func mapView(_ mapView: MKMapView,
                 viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        switch annotation {
        case _ as MKUserLocation:
            // Make a fast exit if the annotation is the `MKUserLocation`, as it's
            // not an annotation view we wish to customize yet.
            return nil

        case let geometry as Geometry: // Probably a .shape is GeoPoint
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: Self.geoPointReuseIdentifier,
                                                                       for: annotation)
            annotationView.clusteringIdentifier = "pointcluster" // TODO: this is _very_ temporary
            return applyStyleTo(annotationView: annotationView, for: geometry)

        case let clusterAnnotation as MKClusterAnnotation:
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: Self.clusterAnnotationReuseIdentifier,
                                                                       for: annotation)
            return applyStyleTo(annotationView: annotationView, forCluster: clusterAnnotation)

        default:
            return nil
        }
    }

    // TODO: this is where the style engine goes :)
    private func applyStyle(to overlayRenderer: MKOverlayRenderer, for feature: Feature?) -> MKOverlayRenderer {

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

    func applyStyle(_ renderer: MKOverlayPathRenderer?, for geometry: Geometry) -> MKOverlayPathRenderer? {

        guard let renderer = renderer else { return nil }

        var objID: ObjectIdentifier? = nil
        if isSelected(geometry.id) {
            objID = geometry.id
        }
        if let f = geometry.parent {
            objID = f.id
        }
        if let selectedID = objID, isSelected(selectedID) {
            renderer.strokeColor = NSColor.black
        }
        return renderer
    }

    func applyStyleTo(annotationView view: MKAnnotationView,
                      forCluster annotation: MKClusterAnnotation) -> MKAnnotationView {

        //            pointAnnotationView.canShowCallout = true

        let pointCount = annotation.memberAnnotations.count
        view.image = KitImage(systemSymbolName: "\(pointCount).circle", accessibilityDescription: "encircled number") ?? clusterAnnotationImage

        //            // Provide the left image icon for the annotation.
        //            pointAnnotationView.leftCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "sf_icon"))

        return view
    }

    func applyStyleTo(annotationView view: MKAnnotationView,
                      for annotation: Geometry) -> MKAnnotationView {

        //            pointAnnotationView.canShowCallout = true

        // Provide the annotation view's image.
        //            let image = #imageLiteral(resourceName: "flag")
        view.image = annotationImage

        //            // Provide the left image icon for the annotation.
        //            pointAnnotationView.leftCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "sf_icon"))

        // Offset the flag annotation so that the flag pole rests on the map coordinate.
        //            let offset = CGPoint(x: image.size.width / 2, y: -(image.size.height / 2) )
        //            pointAnnotationView.centerOffset = offset

        return view
    }
}
