//
//  GeoObjectMKBridge.swift
//  Georg
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

protocol Rendererable {
    func makeRenderer() -> MKOverlayPathRenderer
}

extension GeoPolyline: Rendererable {
    func makeRenderer() -> MKOverlayPathRenderer {
        let renderer = MKPolylineRenderer(polyline: MKPolyline(from: self))
        renderer.fillColor = NSColor.green
        renderer.strokeColor = NSColor.green
        renderer.lineWidth = 4.0
        return renderer
    }
}

extension GeoGeodesicPolyline: Rendererable {
    func makeRenderer() -> MKOverlayPathRenderer {
        let renderer = MKPolylineRenderer(polyline: MKGeodesicPolyline(from: self))
        renderer.fillColor = NSColor.blue
        renderer.strokeColor = NSColor.blue
        renderer.lineWidth = 4.0
        return renderer
    }
}

extension GeoPolygon: Rendererable {
    func makeRenderer() -> MKOverlayPathRenderer {
        let renderer = MKPolygonRenderer(polygon: MKPolygon(from: self))
        renderer.fillColor = NSColor.yellow
        renderer.strokeColor = NSColor.yellow
        renderer.lineWidth = 4.0
        return renderer
    }
}

extension GeoMultiPolyline: Rendererable {
    func makeRenderer() -> MKOverlayPathRenderer {
        let renderer = MKMultiPolylineRenderer(multiPolyline: MKMultiPolyline(from: self))
        renderer.fillColor = NSColor.red
        renderer.strokeColor = NSColor.red
        renderer.lineWidth = 4.0
        return renderer
    }
}

extension GeoMultiPolygon: Rendererable {
    func makeRenderer() -> MKOverlayPathRenderer {
        let renderer = MKMultiPolygonRenderer(multiPolygon: MKMultiPolygon(from: self))
        renderer.fillColor = NSColor.orange
        renderer.strokeColor = NSColor.orange
        renderer.lineWidth = 4.0
        return renderer
    }
}

extension Geometry: MKOverlay {

    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(fromCoordinate: baseInfo!.value.coordinate)
    }

    public var boundingMapRect: MKMapRect {
        return MKMapRect(fromBox: baseInfo!.value.boundingBox!)
    }

    var betterBox: MKMapRect {
        guard let bbox = baseInfo!.value.boundingBox else {
            return MKMapRect(origin: MKMapPoint(coordinate),
                             size: MKMapSize(width: 0.0001, height: 0.0001))
        }
        let mkmaprect = MKMapRect(fromBox: bbox)
        if mkmaprect.isNull || mkmaprect.isZero {
            return MKMapRect(origin: MKMapPoint(coordinate),
                             size: MKMapSize(width: 0.0001, height: 0.0001))
        } else {
            return mkmaprect
        }
    }

    func makeRenderer() -> MKOverlayPathRenderer? {
        guard let r = shape as? Rendererable else { return nil }
        return r.makeRenderer()
    }
}

extension Geometry.Coordinate3D {
    var clcoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}


extension CLLocationCoordinate2D {
    init(fromCoordinate c: Geometry.Coordinate3D) {
        self.init(latitude: c.latitude, longitude: c.longitude)
    }
}

extension MKMapRect {
    init(fromBox b: Geometry.MapBox) {
        self.init(x: b.x, y: b.y, width: b.width, height: b.height)
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
