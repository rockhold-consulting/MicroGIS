//
//  MRMap.swift
//  Georg
//
//  Created by Michael Rockhold on 5/18/24.
//


import SwiftUI
import MapKit
import Combine
import CoreData

#if os(macOS)
import Cocoa
typealias BaseViewRepresentable = NSViewRepresentable
#elseif os(iOS)
import UIKit
typealias BaseViewRepresentable = UIViewRepresentable
#endif

struct MRMap: BaseViewRepresentable {

#if os(macOS)
    typealias NSViewType = MKMapView
#elseif os(iOS)
    typealias UIViewType = MKMapView
#endif

    @Environment(\.managedObjectContext) var moc
    @FetchRequest<Geometry>(sortDescriptors: [])
    private var geometries: FetchedResults<Geometry>

    @Binding var selection: Set<NSManagedObjectID>

    typealias Coordinator = MapCoordinator

    func makeCoordinator() -> Coordinator {
        Coordinator(owner: self, managedObjectContext: moc)
    }

    func makeNSView(context: Self.Context) -> NSViewType {
        defer {
            context.coordinator.load()
        }
        let view = MKMapView()
        view.delegate = context.coordinator
        context.coordinator.mapView = view
        return view
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        context.coordinator.update(selection: selection)
    }
}

extension MRMap {
    class MapCoordinator: NSObject {

        let owner: MRMap
        let managedObjectContext: NSManagedObjectContext
        var previousSelection = Set<NSManagedObjectID>()

        init(owner: MRMap, managedObjectContext: NSManagedObjectContext) {
            self.owner = owner
            self.managedObjectContext = managedObjectContext

            super.init()

            NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext)
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
            let gr = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
            gr.delegate = self
            mapView.addGestureRecognizer(gr)
            if #available(macOS 13.0, *) {
                mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .realistic,
                                                                       emphasisStyle: .muted)
            } else {
                // Fallback on earlier versions
            }
            mapView.isPitchEnabled = true
            mapView.showsPitchControl = true
            //            mv.pitchButtonVisibility = .visible
            mapView.isZoomEnabled = true
            mapView.showsZoomControls = true
            mapView.isRotateEnabled = true
            mapView.showsCompass = true

            reliefTileOverlay = CustomLoadingTileOverlay(urlTemplate: Self.ShadedReliefTilePathTemplate)
            reliefTileOverlay.canReplaceMapContent = true
            mapView.addOverlay(reliefTileOverlay)
        }

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

        private func registerMapAnnotationViews() {
            mapView?.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.geoPointReuseIdentifier)
            mapView?.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.clusterAnnotationReuseIdentifier)
        }

        @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
            guard let userInfo = notification.userInfo,
                  let view = mapView else {
                return
            }

            if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> {

                guard inserts.count > 0 else { return }
                var annotations = [MKAnnotation]()
                var overlays = [MKOverlay]()

                inserts.compactMap { obj in
                    obj as? Geometry
                }
                .forEach { g in
                    let gp = GeometryProxy(geometry: g)
                    if g.wrapped?.shape is GeoPoint {
                        annotations.append(gp)
                    } else {
                        overlays.append(gp)
                    }
                }
                Task { [annotations, overlays] in
                    await MainActor.run {
                        if !annotations.isEmpty {
                            view.addAnnotations(annotations)
                        }
                        if !overlays.isEmpty {
                            view.addOverlays(overlays, level: .aboveRoads)
                        }
                    }
                }
            }

            if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {

                updates.compactMap { obj in
                    obj as? Geometry
                }
                .forEach { geometry in
                    if let r = renderer(forGeometry: geometry) {
                        r.applyStyle(manager: styleManager,
                                     geometry: geometry,
                                     selected: isSelected(geometry.parentID))
                        .setNeedsDisplay()
                    } else {
                        self.refreshAnnotation(geometry: geometry)
                    }
                }
            }
            if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {

                func annotation(with id: NSManagedObjectID) -> MKAnnotation? {
                    if let ann = mapView?.annotations.first(where: { annotation in
                        guard let proxy = annotation as? GeometryProxy else { return false }
                        return proxy.geometryID == id
                    }) {
                        return ann
                    }
                    return nil
                }

                func overlay(with id: NSManagedObjectID) -> MKOverlay? {
                    if let ovr = mapView?.overlays.first(where: { overlay in
                        guard let proxy = overlay as? GeometryProxy else { return false }
                        return proxy.geometryID == id
                    }) {
                        return ovr
                    }
                    return nil
                }

                var annotations = [MKAnnotation]()
                var overlays = [MKOverlay]()

                deletes.compactMap { obj in
                    obj as? Geometry
                }
                .forEach { g in
                    if g.wrapped?.shape is GeoPoint {
                        if let ann = annotation(with: g.objectID) {
                            annotations.append(ann)
                        }
                    } else {
                        if let ovr = overlay(with: g.objectID) {
                            overlays.append(ovr)
                        }
                    }
                }

                Task { [overlays, annotations] in
                    await MainActor.run {
                        mapView?.removeOverlays(overlays)
                        mapView?.removeAnnotations(annotations)
                    }
                }
            }
        }

        func handle(inserts: Set<NSManagedObject>) {
            
        }

        func handle(deletes: Set<NSManagedObject>) {

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
        self.image = KitImage(systemSymbolName: "\(pointCount).circle", accessibilityDescription: "encircled number") ?? MRMap.MapCoordinator.clusterAnnotationImage

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

extension MRMap.MapCoordinator: MKMapViewDelegate, NSGestureRecognizerDelegate {

    func load() {
//        var bigbox = MKMapRect.null
//        var centroids = [MKMapPoint]()
        var annotations = [MKAnnotation]()
        var overlays = [MKOverlay]()
        owner.geometries.forEach { geometry in
//            bigbox = bigbox.union(geometry.betterBox)
//            centroids.append(MKMapPoint(geometry.coordinate))

            let gp = GeometryProxy(geometry: geometry)
            if geometry.wrapped?.shape is GeoPoint {
                annotations.append(gp)
            } else {
                overlays.append(gp)
            }
        }

        Task { [annotations, overlays] in
            await MainActor.run {
                guard let view = mapView else { return }
                view.overlays.forEach { overlay in
                    if !(overlay is CustomLoadingTileOverlay) {
                        view.removeOverlay(overlay)
                    }
                }

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
        }
    }

    func update(selection: Set<NSManagedObjectID>) {
        let newlySelected = selection.subtracting(previousSelection)
        let newlyDeselected = previousSelection.subtracting(selection)
        let toChange = newlySelected.union(newlyDeselected)
        previousSelection.removeAll()
        previousSelection.formUnion(selection)

        Task {
            await MainActor.run {
                if selection.count == 1 {
                    self.flyToSelection(selection.first!)
                }
                self.rerender(changeSet: toChange)
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

    func renderer(forGeometry g: Geometry) -> MKOverlayPathRenderer? {
        if let renderer = rendererCache[g.objectID] {
            return renderer
        } else if let r = g.makeRenderer() {
            rendererCache[g.objectID] = r
            return r
        } else {
            return nil
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
        mapView?.overlays.compactMap { (overlay: MKOverlay) in
            return overlay as? GeometryProxy
        }
        .map { (proxy: GeometryProxy) in
            return geometry(with: proxy.geometryID)
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
            return geometry
        }
        .forEach { (geometry: Geometry) in
            objectTapped(geometry: geometry,
                         continueSelection: commandWasDown)
        }
    }

    func objectTapped(geometry: Geometry,
                      continueSelection: Bool = false) {
        if isSelected(geometry.parentID) {
            deselect(geometry.parentID)
        } else {
            if !continueSelection {
                clearSelection()
            }
            select(geometry.parentID)
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        switch overlay {
        case let geometryProxy as GeometryProxy:

            let geometry = geometry(with: geometryProxy.geometryID)
            let selected = isSelected(geometry.parent.objectID)

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
            let g = geometry(with: geometryProxy.geometryID)
            return mapView.dequeueReusableAnnotationView(withIdentifier: Self.geoPointReuseIdentifier, for: annotation)
                .setClusteringIdentifier(id: "pointcluster") // TODO: this is _very_ temporary
                .setStyle(for: g,
                          selected: isSelected(g.parentID))

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
            guard let proxy = annotation as? GeometryProxy else { return false }
            return proxy.geometryID == geometry.objectID
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
    func rerender(changeSet: Set<NSManagedObjectID>) {
        changeSet.forEach { objectID in
            let selected = isSelected(objectID)
            objectID.geometryChildren(given: owner.moc).forEach { geometry in
                if let r = renderer(forGeometry: geometry) {
                    r.applyStyle(manager: styleManager,
                                 geometry: geometry,
                                 selected: selected)
                    .setNeedsDisplay()
                } else {
                    self.refreshAnnotation(geometry: geometry)
                }
            }
        }
    }

    @MainActor
    func flyToSelection(_ objID:  NSManagedObjectID) {
        if let geokid = objID.geometryChildren(given: owner.moc).first {
            mapView?.setCenter(geokid.coordinate, animated: true)
        }
    }
}

extension MRMap.MapCoordinator {

    func isSelected(_ objID: NSManagedObjectID) -> Bool {
        return owner.selection.contains(objID)
    }

    func clearSelection() {
        owner.selection.removeAll()
    }

    func select(_ objID: NSManagedObjectID) {
        owner.selection.insert(objID)
    }

    func deselect(_ objID: NSManagedObjectID) {
        owner.selection.remove(objID)
    }

    func geometry(with objID: NSManagedObjectID) -> Geometry {
        return owner.moc.object(with: objID) as! Geometry
    }

    func parent(with objID: NSManagedObjectID) -> NSManagedObject {
        return owner.moc.object(with: objID)
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

        owner.geometries.forEach { g in
            add(geometry: g)
        }

        reloadViewControllerFn(annotations, overlays, centroids, bigbox)
    }
}

extension GeometryParent {
    var objectID: NSManagedObjectID {
        return (self as! NSManagedObject).objectID
    }
}
extension Feature: GeometryParent { }
extension Layer: GeometryParent { }

extension Geometry {
    var parentID: NSManagedObjectID {
        return self.parent.objectID
    }

    public var parent: GeometryParent {
        if let fp = featureParent {
            return fp
        } else if let lp = layerParent {
            return lp
        } else {
            fatalError()
        }
    }
}

extension NSManagedObjectID {
    func geometryChildren(given moc: NSManagedObjectContext) -> [Geometry] {
        switch moc.object(with: self) {
        case let lp as Layer:
            return lp.geometries!.array as! [Geometry]
        case let fp as Feature:
            return fp.geometries!.array as! [Geometry]
        default:
            fatalError()
        }
    }

}

//
//#Preview {
//    MRMap(features: FetchResults<Feature>().wrappedValue, selection: [])
//}
