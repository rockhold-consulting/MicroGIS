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

extension MKAnnotationView {

    func setClusteringIdentifier(id: String) -> MKAnnotationView {
        self.clusteringIdentifier = id
        return self
    }

    func setStyle(for annotation: Geometry, selected: Bool) -> MKAnnotationView {

        //            pointAnnotationView.canShowCallout = true

        // Provide the annotation view's image.
        //            let image = #imageLiteral(resourceName: "flag")
        self.image = selected ? MapViewController.selectedAnnotationImage : MapViewController.annotationImage
        self.setSelected(selected, animated: true)

        //            // Provide the left image icon for the annotation.
        //            pointAnnotationView.leftCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "sf_icon"))

        // Offset the flag annotation so that the flag pole rests on the map coordinate.
        //            let offset = CGPoint(x: image.size.width / 2, y: -(image.size.height / 2) )
        //            pointAnnotationView.centerOffset = offset

        return self
    }

    func setStyle(forCluster annotation: MKClusterAnnotation) -> MKAnnotationView {

        //            pointAnnotationView.canShowCallout = true

        let pointCount = annotation.memberAnnotations.count
        self.image = KitImage(systemSymbolName: "\(pointCount).circle", accessibilityDescription: "encircled number") ?? MapViewController.clusterAnnotationImage

        //            // Provide the left image icon for the annotation.
        //            pointAnnotationView.leftCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "sf_icon"))

        return self
    }
}

extension MKOverlayPathRenderer {

    func applyStyle(manager: StyleManager, geometry: Geometry, selected: Bool) -> MKOverlayPathRenderer {

        manager.applyStyle(renderer: self, geometry: geometry)

        if selected {
            self.strokeColor = NSColor.black
        }
        return self
    }
}

class MapViewController: NSViewController {

    @IBOutlet weak var mapView: MKMapView!
    var mapViewModel: MapViewModel!
    let styleManager = SimpleStyleManager()
    var rendererCache = [NSManagedObjectID:MKOverlayPathRenderer]()

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

    static let annotationImage = NSImage(systemSymbolName: "mappin.circle",
                                         accessibilityDescription: "Map pin inside a circle")!
    static let selectedAnnotationImage = NSImage(systemSymbolName: "mappin.circle.fill",
                                         accessibilityDescription: "Selected Map pin inside a circle")!

    static let clusterAnnotationImage = NSImage(systemSymbolName: "seal",
                                                accessibilityDescription: "star-like shape")!

    var commandWasDown: Bool = false

    override var representedObject: Any? {
        didSet {
            if let tc = representedObject as? NSTreeController {
                mapViewModel = MapViewModel(treeController: tc, mapViewController: self)
                reload()
            } else {
                mapViewModel = nil
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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

//        let currentRect = view.visibleMapRect
//        let containsAll = centroids.allSatisfy { p in currentRect.contains(p) }
//
//                if containsAll && view.region.span.longitudeDelta < 4.0 {
//                    // don't reset the view, you can already see the new coordinate
//                    return
//                }
//                view.visibleMapRect = visibleRect
    }

    func reload() {
        mapViewModel?.reload { annotations, overlays, centroids, bigbox in
            Task {
                await self.addToView(annotations: annotations,
                                     overlays: overlays,
                                     centroids: centroids,
                                     visibleRect:bigbox.insetBy(dx: -10000, dy: -10000))
            }
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

    private func makeRenderer(for geometry: Geometry) -> MKOverlayPathRenderer? {
        if let r = geometry.makeRenderer() {
            rendererCache[geometry.objectID] = r
            return r
        } else {
            return nil
        }
    }

    func renderer(forGeometry g: Geometry) -> MKOverlayPathRenderer? {
        if let renderer = rendererCache[g.objectID] {
            return renderer
        } else {
            return makeRenderer(for: g)
        }
    }

    func renderer(forGeometryID gID: NSManagedObjectID) -> MKOverlayPathRenderer? {
        if let renderer = rendererCache[gID] {
            return renderer
        } else {
            return makeRenderer(for: mapViewModel.geometry(with: gID))
        }
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
        mapView.overlays.compactMap { (overlay: MKOverlay) in
            return overlay as? GeometryProxy
        }
        .map { (proxy: GeometryProxy) in
            return mapViewModel.geometry(with: proxy.geometryID)
        }
        .compactMap { (geometry: Geometry) in
            let renderer = renderer(forGeometry: geometry)
            guard let path = renderer?.path,
                  let  viewPoint = renderer?.point(for: mapPoint) else { return nil }

            return (geometry, path, viewPoint)
        }
        .map { (geometry: Geometry, path: CGPath, viewPoint: CGPoint) in
            // If the geometry is a LineString, turn the path from a sequence of line segments
            // into a thin polygon
            return geometry.wrapped?.shape is GeoPolyline || geometry.wrapped?.shape is GeoMultiPolyline
            ? (geometry, path.copy(strokingWithWidth: 500, lineCap: .round, lineJoin: .round, miterLimit: 0), viewPoint)
            : (geometry, path, viewPoint)
        }
        .compactMap { (geometry: Geometry, path: CGPath, viewPoint: CGPoint) in
            guard path.contains(viewPoint) else { return nil }
            return geometry.objectID
        }
        .forEach { (objID: NSManagedObjectID) in
            objectTapped(geometryID: objID, continueSelection: commandWasDown)
        }
    }

    func objectTapped(geometryID: NSManagedObjectID,
                      continueSelection: Bool = false) {
        if mapViewModel.isIDSelected(geometryID) {
            mapViewModel.deselect(geometryID)
        } else {
            if !continueSelection {
                mapViewModel.clearSelection()
            }
            mapViewModel.select(geometryID)
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        switch overlay {
        case let geometryProxy as GeometryProxy:

            let selected = mapViewModel.isIDSelected(geometryProxy.geometryID)
            let geometry = mapViewModel.geometry(with: geometryProxy.geometryID)

            return renderer(forGeometry: geometry)?
                .applyStyle(manager: styleManager,
                            geometry: geometry,
                            selected: selected)
            ?? MKOverlayRenderer(overlay: overlay)

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

        case let geometryProxy as GeometryProxy: // Probably a .shape is GeoPoint
            let id = geometryProxy.geometryID
            return mapView.dequeueReusableAnnotationView(withIdentifier: Self.geoPointReuseIdentifier, for: annotation)
                .setClusteringIdentifier(id: "pointcluster") // TODO: this is _very_ temporary
                .setStyle(for: mapViewModel.geometry(with: id),
                          selected: mapViewModel.isIDSelected(id))

        case let clusterAnnotation as MKClusterAnnotation:
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: Self.clusterAnnotationReuseIdentifier,
                                                                       for: annotation)
            return annotationView.setStyle(forCluster: clusterAnnotation)

        default:
            return nil
        }
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("did SELECT an annotation")
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        print("did DESELECT an annotation")
    }

    func doSelectAnnotation(objID: NSManagedObjectID, selected: Bool) {
        guard let ann = mapView.annotations.first(where: { annotation in
            guard let proxy = annotation as? GeometryProxy else { return false }
            return proxy.geometryID == objID
        }) else {
            return
        }
        mapView.removeAnnotation(ann)
        mapView.addAnnotation(ann)
    }

    @MainActor
    func rerenderSelection(changeSet: MapViewModel.IDSet) {
        changeSet.forEach { objID in
            let selected = mapViewModel.isIDSelected(objID)
            if let r = renderer(forGeometryID: objID) {
                r.applyStyle(manager: styleManager,
                                             geometry: mapViewModel.geometry(with: objID),
                                             selected: selected)
                                 .setNeedsDisplay()
            } else {
                self.doSelectAnnotation(objID: objID, selected: selected)
            }
        }
    }

}
