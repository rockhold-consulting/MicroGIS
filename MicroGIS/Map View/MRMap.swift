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
typealias MGGestureRecognizer = NSGestureRecognizer
typealias MGGestureRecognizerDelegate = NSGestureRecognizerDelegate
typealias MGEvent = NSEvent

#elseif os(iOS)
import UIKit
typealias BaseViewRepresentable = UIViewRepresentable
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

protocol MRMapAnnotationViewHitHandler {
    func hit(annotationView: MRMapAnnotationView, commandIsDown: Bool)
}

@objc class MRMapAnnotationView: MKAnnotationView, MGGestureRecognizerDelegate {

    // TODO: rethink this?
    static var reuseIdentifier = "\(NSStringFromClass(MGPoint.self)).GeoPointReuseIdentifier"
    static let clusterAnnotationReuseIdentifier = MKMapViewDefaultClusterAnnotationViewReuseIdentifier

    var hitHandler: MRMapAnnotationViewHitHandler?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.canShowCallout = false
        let gr = HitGestureRecognizer(target: self, action: #selector(handleClick))
        gr.delegate = self
        self.addGestureRecognizer(gr)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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

    @objc func handleClick(gestureRecognizer: HitGestureRecognizer) {
        hitHandler?.hit(annotationView: self, commandIsDown: gestureRecognizer.commandIsDown)
    }

    var geometry: MGPoint? {
        return self.annotation as? MGPoint
    }

    func setHitHandler(_ hitHandler: MRMapAnnotationViewHitHandler) -> MRMapAnnotationView {
        self.hitHandler = hitHandler
        return self
    }
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

        var selectionFlasher: Timer!

        init(mrMap: MRMap) {
            self.mrMap = mrMap

            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: mrMap.managedObjectContext)

            selectionFlasher = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] timer in
                guard let mv = self?.mapView else {
                    return
                }

                mrMap.selection.forEach { g in
                    if let av = mv.view(for: g) {

                        let sz = av.image!.size
                        #if os(macOS)
                        if sz.width != 35 {
                            av.image = NSImage(cgImage: (av.image?.cgImage(forProposedRect: nil, context: nil, hints: nil))!, size: NSSize(width: 35, height: 35))
                        } else {
                            av.image = NSImage(cgImage: (av.image?.cgImage(forProposedRect: nil, context: nil, hints: nil))!, size: NSSize(width: 25, height: 25))
                        }
                        #endif
                        #if os(iOS)
                        var config: UIImage.SymbolConfiguration
                        if sz.width != 35 {
                            config = UIImage.SymbolConfiguration(pointSize: 35)
                        } else {
                            config = UIImage.SymbolConfiguration(pointSize: 25)
                        }
                        av.image = UIImage(cgImage: av.image!.cgImage!).withConfiguration(config)

                        #endif

                    } else if let r = mv.renderer(for: g) as? MKOverlayPathRenderer {

                        let lineWidth = r.lineWidth
                        if lineWidth != 5.0 {
                            r.lineWidth = 5.0
                        } else {
                            r.lineWidth = 4.0
                        }
                        r.setNeedsDisplay()
                    }
                }
            }

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


        private func registerMapAnnotationViews() {
            mapView?.register(MRMapAnnotationView.self, forAnnotationViewWithReuseIdentifier: MRMapAnnotationView.reuseIdentifier)
            mapView?.register(MRMapAnnotationView.self, forAnnotationViewWithReuseIdentifier: MRMapAnnotationView.clusterAnnotationReuseIdentifier)
        }

        private func renderer(for renderable: (any Renderable)?) -> MKOverlayPathRenderer? {
            return renderable?.makeRenderer(isSelected: isSelected(renderable))
        }

        @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
            guard let userInfo = notification.userInfo,
                  let _ = mapView else {
                return
            }

            // BUGBUG: restrict scope of the geometries we're interested in to just those in current featureCollection
            let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? []
            let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? []

            if !inserts.isEmpty && !deletes.isEmpty {
                update(mrMap: mrMap)
            }

            if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updates.isEmpty {
                updates.compactMap({ $0 as? Geometry }).forEach { geometry in
                    if let r = renderer(for: geometry as? (any Renderable)) {
                        r.setNeedsDisplay()
                    } else {
                        self.refreshAnnotation(geometry: geometry)
                    }
                }
            }
        }
    }
}

extension MRMap.MapCoordinator: MKMapViewDelegate, MRMapAnnotationViewHitHandler {
    func hit(annotationView: MRMapAnnotationView, commandIsDown: Bool) {
        if let g = annotationView.annotation as? Geometry {
            objectTapped(geometry: g, continueSelection: commandIsDown)
        }
    }
    

    func update(mrMap: MRMap) {
        self.mrMap = mrMap
        let newlySelected = mrMap.selection.subtracting(previousSelection)
        let newlyDeselected = previousSelection.subtracting(mrMap.selection)
        let toChange = newlySelected.union(newlyDeselected)
        previousSelection.removeAll()
        previousSelection.formUnion(mrMap.selection)

        let existingAnnotations = mapView!.annotations.filter( { $0 is Geometry }) as! [Geometry]
        let existingOverlays = mapView!.overlays.filter( { $0 is Geometry }) as! [Geometry]

        let oldset = Set(existingAnnotations)
        let newset = Set(mrMap.geometries.filter { $0 is MGPoint })
        let toRemove = oldset.subtracting(newset)
        let toAdd = newset.subtracting(oldset)

        let oldOverlaySet = Set(existingOverlays)
        let newOverlaySet = Set(mrMap.geometries.filter { !($0 is MGPoint) })
        let overlaysToRemove = oldOverlaySet.subtracting(newOverlaySet)
        let overlaysToAdd = newOverlaySet.subtracting(oldOverlaySet)

        Task { [toChange, toRemove, toAdd, overlaysToRemove, overlaysToAdd] in
            await MainActor.run {
                mapView?.addOverlays(Array<Geometry>(overlaysToAdd), level: .aboveRoads)
                mapView?.addAnnotations(Array<Geometry>(toAdd))

                mapView?.removeOverlays(Array<Geometry>(overlaysToRemove))
                mapView?.removeAnnotations(Array<Geometry>(toRemove))

                self.rerender(changeSet: toChange)

                if mrMap.selection.count == 1 {
                    self.flyToSelection(mrMap.selection.first!)
                }
            }
        }
    }

    func clicked(annotationView: MRMapAnnotationView) {
        print("annotationView")
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

        case let mgOverlay as any Renderable:
            return mgOverlay.makeRenderer(isSelected: isSelected(mgOverlay as Geometry))

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

        case let g as MGPoint: // Probably a .shape is GeoPoint
            let decorator = MGPointDecorator(point: g, isSelected: isSelected(g))
            return decorator.decorate(view: (mapView.dequeueReusableAnnotationView(withIdentifier: MRMapAnnotationView.reuseIdentifier, for: annotation) as! MRMapAnnotationView))
                .setHitHandler(self)

        case let clusterAnnotation as MKClusterAnnotation:
            let decorator = MGClusterDecorator(annotation: clusterAnnotation)
            return decorator.decorate(view: (mapView.dequeueReusableAnnotationView(withIdentifier: MRMapAnnotationView.clusterAnnotationReuseIdentifier,
                                                                                   for: annotation) as! MRMapAnnotationView))

        default:
            print("unknown annotation")
            return nil
        }
    }

    func refreshAnnotation(geometry: Geometry) {
        Task {
            await MainActor.run {
                mapView?.removeAnnotation(geometry)
                mapView?.addAnnotation(geometry)
            }
        }
    }

    @MainActor
    func rerender(changeSet: Set<Geometry>) {
        changeSet.forEach { geometry in
            if geometry is MGPoint {
                mapView?.removeAnnotation(geometry)
                mapView?.addAnnotation(geometry)
//                self.refreshAnnotation(geometry: geometry)
            } else {
                mapView?.removeOverlay(geometry)
                mapView?.addOverlay(geometry)
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

        typealias GPV = (geometry: Geometry, path: CGPath, viewPoint: CGPoint)

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
        let clickedOn: [Geometry]? = mapView?.overlays.compactMap { (overlay: MKOverlay) in
            return overlay as? Geometry
        }
        .compactMap { (geometry: Geometry) in
            let renderer = renderer(for: geometry as? (any Renderable))
            guard let path = renderer?.path,
                  let  viewPoint = renderer?.point(for: mapPoint) else { return nil }

            return GPV(geometry:geometry, path: path, viewPoint:viewPoint)
        }
        .map { (geometry: Geometry, path: CGPath, viewPoint: CGPoint) in
            // If the geometry is a LineString, turn the path from a sequence of line segments
            // into a thin polygon
            // TODO: use the current zoom level to adjust the width of the thin polygon appropriately
            let p = geometry.isPolylineish
            ? path.copy(strokingWithWidth: 500, lineCap: .round, lineJoin: .round, miterLimit: 0)
            : path

            return GPV(geometry:geometry, path: p, viewPoint:viewPoint)
        }
        .compactMap { gpv in
            guard gpv.path.contains(gpv.viewPoint) else { return nil }
            return gpv.geometry
        }

        if let co = clickedOn {
            if co.isEmpty {
                clearSelection()
            } else {
                co.forEach { (geometry: Geometry) in
                    objectTapped(geometry: geometry,
                                 continueSelection: hitGestureRecognizer.commandIsDown)
                }
            }
        } else {
            clearSelection()
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
