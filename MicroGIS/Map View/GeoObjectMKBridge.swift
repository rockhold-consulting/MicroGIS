//
//  GeoObjectMKBridge.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 12/17/23.
//

import Foundation
#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#endif
import MapKit
import BinaryCodable
import CoreData

protocol Rendererable {
    func makeRenderer(geometry: Geometry) -> MKOverlayPathRenderer
}

extension GeoPolyline: Rendererable {
    @objc func makeRenderer(geometry: Geometry) -> MKOverlayPathRenderer {
        return MKPolylineRenderer(polyline: MKPolyline(from: self))
    }
}

extension GeoCircle: Rendererable {
    @objc func makeRenderer(geometry: Geometry) -> MKOverlayPathRenderer {
        return MKCircleRenderer(circle: MKCircle(center: geometry.center.clcoordinate, radius: self.radius))
    }
}

extension GeoGeodesicPolyline {
    @objc override func makeRenderer(geometry: Geometry) -> MKOverlayPathRenderer {
        return MKPolylineRenderer(polyline: MKGeodesicPolyline(from: self))
    }
}

extension GeoPolygon: Rendererable {
    @objc func makeRenderer(geometry: Geometry) -> MKOverlayPathRenderer {
        return MKPolygonRenderer(polygon: MKPolygon(from: self))
    }
}

extension GeoMultiPolyline: Rendererable {
    @objc func makeRenderer(geometry: Geometry) -> MKOverlayPathRenderer {
        return MKMultiPolylineRenderer(multiPolyline: MKMultiPolyline(from: self))
    }
}

extension GeoMultiPolygon: Rendererable {
    @objc func makeRenderer(geometry: Geometry) -> MKOverlayPathRenderer {
        return MKMultiPolygonRenderer(multiPolygon: MKMultiPolygon(from: self))
    }
}

class GeometryProxy: NSObject, MKAnnotation, MKOverlay {
    let geometry: Geometry
    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect
    let title: String?
    let subtitle: String?

    init(
        geometry: Geometry,
        coordinate: CLLocationCoordinate2D,
        boundingMapRect: MKMapRect,
        title: String?,
        subtitle: String?
    ) {
        self.geometry = geometry
        self.coordinate = coordinate
        self.boundingMapRect = boundingMapRect
        self.title = title
        self.subtitle = subtitle
    }

    convenience init(geometry: Geometry) {
        self.init(
            geometry: geometry,
            coordinate: geometry.center.clcoordinate,
            boundingMapRect: geometry.boundingMapRect ?? MKMapRect.null,
            title: geometry.title,
            subtitle: nil
        )
    }
}

extension Geometry {

    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(fromCoordinate: self.center)
    }

    public var boundingMapRect: MKMapRect? {
        return MKMapRect(fromBoundingVolume: self.boundingVolume)
    }

    var betterBox: MKMapRect {
        let mkmaprect = MKMapRect(fromBoundingVolume: self.boundingVolume)
        if mkmaprect.isNull || mkmaprect.isZero {
            return MKMapRect(origin: MKMapPoint(coordinate),
                             size: MKMapSize(width: 0.0001, height: 0.0001))
        } else {
            return mkmaprect
        }
    }

    func renderer(selected: Bool = false) -> MKOverlayRenderer? {
        return self.feature?.collection?.currentStylesheet.renderer(for: self, selected: selected)
    }
}

extension Coordinate3D {
    var clcoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}


extension CLLocationCoordinate2D {
    init(fromCoordinate c: Coordinate3D) {
        self.init(latitude: c.latitude, longitude: c.longitude)
    }
}

extension MKMapRect {
    init(fromBoundingVolume v: Geometry.BoundingVolume) {
        self.init(x: v.x, y: v.y, width: v.w, height: v.h)
    }
}

extension MKPolyline {
    convenience init(from polyline: GeoPolyline) {
        let coords = polyline.coordinates.map { gp in
            CLLocationCoordinate2D(latitude: gp.latitude, longitude: gp.longitude)
        }
        self.init(coordinates: coords, count: coords.count)
    }
}

extension MKGeodesicPolyline {
    convenience init(from polyline: GeoGeodesicPolyline) {
        let coords = polyline.coordinates.map { gp in
            CLLocationCoordinate2D(latitude: gp.latitude, longitude: gp.longitude)
        }
        self.init(coordinates: coords, count: coords.count)
    }
}

extension MKPolygon {
    convenience init(from geoShape: GeoPolygon) {
        let coords = geoShape.coordinates.map { gp in
            CLLocationCoordinate2D(latitude: gp.latitude, longitude: gp.longitude)
        }
        if geoShape.innerPolygons.count == 0 {
            self.init(coordinates: coords, count: coords.count)
        } else {
            self.init(coordinates: coords, count: coords.count, interiorPolygons: geoShape.innerPolygons.map { geoPolygon in
                MKPolygon(from: geoPolygon)
            })
        }
    }
}

extension MKMultiPolyline {
    convenience init(from geoShape: GeoMultiPolyline) {
        self.init(geoShape.polylines.map { geoPolyline in
            MKPolyline(from: geoPolyline)
        })
    }
}

extension MKMultiPolygon {
    convenience init(from geoShape: GeoMultiPolygon) {
        self.init(geoShape.polygons.map { geoPolygon in
            MKPolygon(from: geoPolygon)
        })
    }
}

extension MKMapRect {

    static let zero: MKMapRect = MKMapRect(x:0,y:0,width:0,height:0)

    var isZero: Bool {
        MKMapRectEqualToRect(self, MKMapRect.zero)
    }

    func allUnion(_ rects: [MKMapRect]) -> MKMapRect {
        return rects.reduce(self) { partialResult, rect in
            return partialResult.union(rect)
        }
    }
}

extension MKMapView {
    func pointToMapPoint(_ point: CGPoint) -> MKMapPoint {
        return MKMapPoint(self.convert(point, toCoordinateFrom: self))
    }
}
