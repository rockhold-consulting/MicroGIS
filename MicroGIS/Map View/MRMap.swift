//
//  MRMap.swift
//  MicroGIS
//
//  Copyright 2024, Michael Rockhold (dba Rockhold Software)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  The license is provided with this work, or you may obtain a copy
//  of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//  Created by Michael Rockhold on 5/18/24.
//


import SwiftUI
import MapKit
import Combine
import CoreData

#if os(macOS)
import Cocoa
import AppKit
typealias BaseViewRepresentable = NSViewRepresentable
func kitImage(symbolName: String, accessibilityDescription: String) -> NSImage {
    return NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityDescription) ?? NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "uh oh")!
}
typealias MGGestureRecognizer = NSGestureRecognizer
typealias MGGestureRecognizerDelegate = NSGestureRecognizerDelegate
typealias MGEvent = NSEvent

#elseif os(iOS)
import UIKit
typealias BaseViewRepresentable = UIViewRepresentable
func kitImage(symbolName: String, accessibilityDescription: String) -> UIImage {
    return UIImage(systemName: symbolName) ?? UIImage(systemName: "exclamationmark.triangle")!
}
typealias MGGestureRecognizer = UIGestureRecognizer
typealias MGGestureRecognizerDelegate = UIGestureRecognizerDelegate
typealias MGEvent = UIEvent
#endif

#if os(macOS)
class HitGestureRecognizer: NSClickGestureRecognizer {
    var commandIsDown: Bool = false
}
#endif
#if os(iOS)
class HitGestureRecognizer: UITapGestureRecognizer {
    var commandIsDown: Bool {
        return self.modifierFlags.contains(.command)
    }
}
#endif

extension Geometry: MKAnnotation, MKOverlay {
    public var coordinate: CLLocationCoordinate2D { return center }
    public var boundingMapRect: MKMapRect { return MKMapRect.world }
    public var title: String? { return feature?.title }
    public var subtitle: String? { return nil }
}


struct MRMap: BaseViewRepresentable {

    @Environment(\.managedObjectContext) var managedObjectContext
    let geometries: [Geometry]
    @Binding var selection: Set<Geometry>

    typealias Coordinator = MapCoordinator

    func makeCoordinator() -> Coordinator {
        MapCoordinator(mrMap: self)
    }

    func makeKitView(context: Self.Context) -> MKMapView {
        let view = MKMapView()
        view.delegate = context.coordinator
        context.coordinator.mapView = view
        return view
    }

#if os(macOS)
    func makeNSView(context: Self.Context) -> MKMapView {
        return makeKitView(context: context)
    }
    func updateNSView(_ nsView: MKMapView, context: Context) {
        context.coordinator.update(mrMap: self)
    }
#elseif os(iOS)
    func makeUIView(context: Self.Context) -> MKMapView {
        return makeKitView(context: context)
    }
    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.update(mrMap: self)
    }
#endif
}

extension MRMap {

    class MapCoordinator: NSObject {
        var mrMap: MRMap!
        var previousSelection = Set<Geometry>()

        init(mrMap: MRMap) {
            self.mrMap = mrMap
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: mrMap.managedObjectContext)
        }

        weak var mapView: MKMapView? = nil {
            didSet {
                if let mv = mapView {
                    self.didLoad(mapView: mv)
                }
            }
        }
        
        private func didLoad(mapView: MKMapView) {
            registerMapAnnotationViews()

            #if os(macOS)
            if #available(macOS 13.0, *) {
                mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .realistic,
                                                                       emphasisStyle: .muted)
            } else {
                // Fallback on earlier versions
            }
            mapView.showsZoomControls = true
            mapView.showsPitchControl = true
            #endif

            #if os(iOS)
            if #available(iOS 17.0, *) {
                mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .realistic,
                                                                       emphasisStyle: .muted)
            } else {
                // Fallback on earlier versions
            }
            #endif

            let gr = HitGestureRecognizer(target: self, action: #selector(handleClick))
            gr.delegate = self
            mapView.addGestureRecognizer(gr)

            mapView.isPitchEnabled = true
            mapView.isZoomEnabled = true
            mapView.isRotateEnabled = true
            mapView.showsCompass = true

            reliefTileOverlay = CustomLoadingTileOverlay(urlTemplate: Self.ShadedReliefTilePathTemplate)
            reliefTileOverlay.canReplaceMapContent = true
            mapView.addOverlay(reliefTileOverlay)
        }

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

        static let annotationImage = kitImage(symbolName: "mappin.circle",
                                             accessibilityDescription: "Map pin inside a circle")
        static let selectedAnnotationImage = kitImage(symbolName: "mappin.circle.fill",
                                             accessibilityDescription: "Selected Map pin inside a circle")

        static let clusterAnnotationImage = kitImage(symbolName: "seal",
                                                    accessibilityDescription: "star-like shape")


        private func registerMapAnnotationViews() {
            mapView?.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.geoPointReuseIdentifier)
            mapView?.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.clusterAnnotationReuseIdentifier)
        }

        func loadOverlays(annotations: [MKAnnotation], overlays: [MKOverlay]) {
            guard let mp = mapView else { return }
            if !annotations.isEmpty {
                mp.addAnnotations(annotations)
            }
            if !overlays.isEmpty {
                mp.addOverlays(overlays, level: .aboveRoads)
            }
        }

        func unloadOverlays() {
            guard let mp = mapView else { return }
            let overlays = mp.overlays.filter({ overlay in
                return !(overlay is CustomLoadingTileOverlay)
            })
            mp.removeAnnotations(mp.annotations)
            mp.removeOverlays(overlays)
        }

        @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
            guard let userInfo = notification.userInfo,
                  let view = mapView else {
                return
            }

            // BUGBUG: restrict scope of the geometries we're interested in to just those in current featureCollection
            if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> {
                handle(mapView: view, inserts: inserts.compactMap({ $0 as? Geometry }))
            }
            if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
                handle(mapView: view, updates: updates.compactMap({ $0 as? Geometry }))
            }
            if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
                handle(mapView: view, deletes: deletes.compactMap({ $0 as? Geometry }))
            }
        }

        func handle(mapView: MKMapView, updates: [Geometry]) {
            updates.forEach { geometry in
                if let r = geometry.renderer(selected: isSelected(geometry)) {
                    r.setNeedsDisplay()
                } else {
                    self.refreshAnnotation(geometry: geometry)
                }
            }
        }

        func handle(mapView: MKMapView, inserts: [Geometry]) {
            guard inserts.count > 0 else { return }
            var annotations = [MKAnnotation]()
            var overlays = [MKOverlay]()

            inserts.forEach { (g: Geometry) in
                if g.isPoint {
                    annotations.append(g)
                } else {
                    overlays.append(g)
                }
            }
            Task { [annotations, overlays] in
                await MainActor.run {
                    loadOverlays(annotations: annotations, overlays: overlays)
                }
            }
        }

        func handle(mapView: MKMapView, deletes: [Geometry]) {

            func annotation(with geometry: Geometry) -> MKAnnotation? {
                if let ann = mapView.annotations.first(where: { annotation in
                    guard let g = annotation as? Geometry else { return false }
                    return g == geometry
                }) {
                    return ann
                }
                return nil
            }

            func overlay(with geometry: Geometry) -> MKOverlay? {
                if let ovr = mapView.overlays.first(where: { overlay in
                    guard let g = overlay as? Geometry else { return false }
                    return g == geometry
                }) {
                    return ovr
                }
                return nil
            }

            var annotations = [MKAnnotation]()
            var overlays = [MKOverlay]()

            deletes.forEach { g in
                if g.isPoint {
                    if let ann = annotation(with: g) {
                        annotations.append(ann)
                    }
                } else {
                    if let ovr = overlay(with: g) {
                        overlays.append(ovr)
                    }
                }
            }

            Task { [overlays, annotations] in
                await MainActor.run {
                    mapView.removeOverlays(overlays)
                    mapView.removeAnnotations(annotations)
                }
            }
        }
    }
}

extension MKAnnotationView {
    func setClusteringIdentifier(id: String) -> MKAnnotationView {
        self.clusteringIdentifier = id
        return self
    }

    func setStyle(for annotation: Geometry, selected: Bool) -> MKAnnotationView {

        //            pointAnnotationView.canShowCallout = true

        // Provide the annotation view's image.
        //            let image = #imageLiteral(resourceName: "flag")
        self.image = selected ? MRMap.MapCoordinator.selectedAnnotationImage : MRMap.MapCoordinator.annotationImage
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
        self.image = kitImage(symbolName: "\(pointCount).circle", accessibilityDescription: "encircled number")

        //            // Provide the left image icon for the annotation.
        //            pointAnnotationView.leftCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "sf_icon"))

        return self
    }
}

extension MRMap.MapCoordinator: MKMapViewDelegate {

    func createOverlays(from geometries: [Geometry]) -> ([MKAnnotation], [MKOverlay]) {
        var annotations = [MKAnnotation]()
        var overlays = [MKOverlay]()
        geometries.forEach { geometry in
            if geometry.isPoint {
                annotations.append(geometry)
            } else {
                overlays.append(geometry)
            }
        }
        return (annotations, overlays)
    }

    func update(mrMap: MRMap) {
        self.mrMap = mrMap
        let newlySelected = mrMap.selection.subtracting(previousSelection)
        let newlyDeselected = previousSelection.subtracting(mrMap.selection)
        let toChange = newlySelected.union(newlyDeselected)
        previousSelection.removeAll()
        previousSelection.formUnion(mrMap.selection)

        let (annotations, overlays) = createOverlays(from: mrMap.geometries)

        Task { [annotations, overlays] in
            await MainActor.run {
                unloadOverlays()
                loadOverlays(annotations: annotations, overlays: overlays)

                if mrMap.selection.count == 1 {
                    self.flyToSelection(mrMap.selection.first!)
                }
                self.rerender(changeSet: toChange)
            }
        }
    }

    func objectTapped(geometry: Geometry,
                      continueSelection: Bool = false) {
        if isSelected(geometry) {
            deselect(geometry)
        } else {
            if !continueSelection {
                clearSelection()
            }
            select(geometry)
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        switch overlay {
        case let geometry as Geometry:
            return geometry.renderer(selected: isSelected(geometry))
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

        case let g as Geometry: // Probably a .shape is GeoPoint
            return mapView.dequeueReusableAnnotationView(withIdentifier: Self.geoPointReuseIdentifier, for: annotation)
                .setClusteringIdentifier(id: "pointcluster") // TODO: this is _very_ temporary
                .setStyle(for: g,
                          selected: isSelected(g))

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

    func refreshAnnotation(geometry: Geometry) {
        guard let ann = mapView?.annotations.first(where: { annotation in
            guard let g = annotation as? Geometry else { return false }
            return g == geometry
        }) else {
            return
        }
        Task {
            await MainActor.run {
                mapView?.removeAnnotation(ann)
                mapView?.addAnnotation(ann)
            }
        }
    }

    @MainActor
    func rerender(changeSet: Set<Geometry>) {
        changeSet.forEach { geometry in
            let selected = isSelected(geometry)
            if let r = geometry.renderer(selected: selected) {
                r.setNeedsDisplay()
            } else {
                self.refreshAnnotation(geometry: geometry)
            }
        }
    }

    func flyToSelection(_ geometry:  Geometry) {
        mapView?.setCenter(geometry.center, animated: true)
    }
}

extension MRMap.MapCoordinator: MGGestureRecognizerDelegate {

    #if os(macOS)
    @MainActor
    @objc func gestureRecognizer(
        _ gestureRecognizer: MGGestureRecognizer,
        shouldAttemptToRecognizeWith event: MGEvent
    ) -> Bool {
        if let hitGestureRecognizer = gestureRecognizer as? HitGestureRecognizer {
            hitGestureRecognizer.commandIsDown = event.modifierFlags.contains(.command)
        }
        return true
    }
    #endif

    @objc func handleClick(gestureRecognizer: MGGestureRecognizer) {

        guard let hitGestureRecognizer = gestureRecognizer as? HitGestureRecognizer else {
            return
        }
        let loc = hitGestureRecognizer.location(in: mapView)
        guard let mapPoint = mapView?.pointToMapPoint(loc) else { return }

        // Let's do this the naively stupid way first
        // Given a MapPoint, find the overlay the user has clicked on.
        // For each geometry, create the appropriate overlay renderer,
        // and then use that to generate the Path. For polylines, we go
        // further and create the path that outlines a wide stroke along
        // that path.
        // Finally, use cgpath operations to determine whether this point is
        // inside that generated path.
        mapView?.overlays.compactMap { (overlay: MKOverlay) in
            return overlay as? Geometry
        }
        .compactMap { (geometry: Geometry) in
            let renderer = geometry.renderer(selected: self.isSelected(geometry)) as? MKOverlayPathRenderer
            guard let path = renderer?.path,
                  let  viewPoint = renderer?.point(for: mapPoint) else { return nil }

            return (geometry, path, viewPoint)
        }
        .map { (geometry: Geometry, path: CGPath, viewPoint: CGPoint) in
            // If the geometry is a LineString, turn the path from a sequence of line segments
            // into a thin polygon
            // TODO: use the current zoom level to adjust the width of the thin polygon appropriately
            return geometry.isPolylineish
            ? (geometry, path.copy(strokingWithWidth: 500, lineCap: .round, lineJoin: .round, miterLimit: 0), viewPoint)
            : (geometry, path, viewPoint)
        }
        .compactMap { (geometry: Geometry, path: CGPath, viewPoint: CGPoint) in
            guard path.contains(viewPoint) else { return nil }
            return geometry
        }
        .forEach { (geometry: Geometry) in
            objectTapped(geometry: geometry,
                         continueSelection: hitGestureRecognizer.commandIsDown)
        }
    }
}

extension MRMap.MapCoordinator {

    func isSelected(_ geometry: Geometry?) -> Bool {
        guard let g = geometry else { return false }
        return mrMap.selection.contains(g)
    }

    func clearSelection() {
        mrMap.selection.removeAll()
    }

    func select(_ geometry: Geometry?) {
        guard let g = geometry else { return }
        mrMap.selection.insert(g)
    }

    func deselect(_ geometry: Geometry?) {
        guard let g = geometry else { return }
        mrMap.selection.remove(g)
    }
}

//#Preview {
//    MRMap(features: FetchResults<Feature>().wrappedValue, selection: [])
//}
