//
//  MRMap.swift
//  Georg
//
//  Created by Michael Rockhold on 5/18/24.
//


import SwiftUI
import MapKit


#if os(macOS)
import Cocoa
typealias BaseViewRepresentable = NSViewRepresentable
#elseif os(iOS)
import UIKit
typealias BaseViewRepresentable = UIViewRepresentable
#endif

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


struct MRMap: BaseViewRepresentable {

#if os(macOS)
    typealias NSViewType = MKMapView
#elseif os(iOS)
    typealias UIViewType = MKMapView
#endif

    @Environment(\.managedObjectContext) var moc

    let features: FetchedResults<Feature>
    @Binding var selection: Set<Feature>

    typealias Coordinator = MapCoordinator

    func makeCoordinator() -> Coordinator {
        Coordinator(owner: self)
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
        (context.coordinator as Coordinator).load()
    }
}

extension MRMap {
    class MapCoordinator: NSObject {
        typealias IDSet = Set<NSManagedObjectID>

        var owner: MRMap? = nil
        var previousSelectedGeometries = IDSet()

        var selectedGeometries = IDSet() {
            willSet {
                previousSelectedGeometries = selectedGeometries
            }
            didSet {
                let newlySelected = selectedGeometries.subtracting(previousSelectedGeometries)
                let newlyDeselected = previousSelectedGeometries.subtracting(selectedGeometries)
                let toChange = newlySelected.union(newlyDeselected)
                Task {
                    await self.rerenderSelection(changeSet: toChange)
                }
            }
        }

        init(owner: MRMap? = nil) {
            self.owner = owner
        }

        weak var mapView: MKMapView? = nil {
            didSet {
                if mapView != nil {
                    registerMapAnnotationViews()
                }
            }
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
    }
}

extension MRMap.MapCoordinator: MKMapViewDelegate, NSGestureRecognizerDelegate {

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

    func load() {
        print("LOADING \(owner!.selection)")
        reload { annotations, overlays, centroids, bigbox in
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
            return makeRenderer(for: geometry(with: gID))
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
//        mapView?.overlays.compactMap { (overlay: MKOverlay) in
//            return overlay as? GeometryProxy
//        }
//        .map { (proxy: GeometryProxy) in
//            return geometry(with: proxy.geometryID)
//        }

        [Geometry]()
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
        if isIDSelected(geometryID) {
            deselect(geometryID)
        } else {
            if !continueSelection {
                clearSelection()
            }
            select(geometryID)
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        switch overlay {
        case let geometryProxy as GeometryProxy:

            let selected = isIDSelected(geometryProxy.geometryID)
            let geometry = geometry(with: geometryProxy.geometryID)

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
                .setStyle(for: geometry(with: id),
                          selected: isIDSelected(id))

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
        guard let ann = mapView?.annotations.first(where: { annotation in
            guard let proxy = annotation as? GeometryProxy else { return false }
            return proxy.geometryID == objID
        }) else {
            return
        }
        mapView?.removeAnnotation(ann)
        mapView?.addAnnotation(ann)
    }

    @MainActor
    func rerenderSelection(changeSet: IDSet) {
        changeSet.forEach { objID in
            let selected = isIDSelected(objID)
            if let r = renderer(forGeometryID: objID) {
                r.applyStyle(manager: styleManager,
                                             geometry: geometry(with: objID),
                                             selected: selected)
                                 .setNeedsDisplay()
            } else {
                self.doSelectAnnotation(objID: objID, selected: selected)
            }
        }
    }

}

extension MRMap.MapCoordinator {

    func isIDSelected(_ objID: NSManagedObjectID) -> Bool {
        return selectedGeometries.contains(objID)
    }

    func clearSelection() {
//        treeController.removeSelectionIndexPaths(treeController.selectionIndexPaths)
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

//        if let node = findTreeNode(for: objID, under: treeController.arrangedObjects) {
//            treeController.addSelectionIndexPaths([node.indexPath])
//        }
    }

    func deselect(_ objID: NSManagedObjectID) {
//        if let node = findTreeNode(for: objID, under: treeController.arrangedObjects) {
//            treeController.removeSelectionIndexPaths([node.indexPath])
//        }
    }

    func geometry(with objID: NSManagedObjectID) -> Geometry {
        return owner!.moc.object(with: objID) as! Geometry
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

        owner?.features.forEach { feature in
            guard let featureKids = feature.kidArray else { return }
            add(geometries: featureKids as? [Geometry])
        }

        reloadViewControllerFn(annotations, overlays, centroids, bigbox)
    }
}

//
//#Preview {
//    MRMap(features: FetchResults<Feature>().wrappedValue, selection: [])
//}
