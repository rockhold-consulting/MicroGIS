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
        return MKPolylineRenderer(polyline: MKPolyline(from: self))
    }
}

extension GeoCircle: Rendererable {
    func makeRenderer() -> MKOverlayPathRenderer {
        return MKCircleRenderer(circle: MKCircle(center: self.center.clcoordinate, radius: self.radius))
    }
}

extension GeoGeodesicPolyline: Rendererable {
    func makeRenderer() -> MKOverlayPathRenderer {
        return MKPolylineRenderer(polyline: MKGeodesicPolyline(from: self))
    }
}

extension GeoPolygon: Rendererable {
    func makeRenderer() -> MKOverlayPathRenderer {
        return MKPolygonRenderer(polygon: MKPolygon(from: self))
    }
}

extension GeoMultiPolyline: Rendererable {
    func makeRenderer() -> MKOverlayPathRenderer {
        return MKMultiPolylineRenderer(multiPolyline: MKMultiPolyline(from: self))
    }
}

extension GeoMultiPolygon: Rendererable {
    func makeRenderer() -> MKOverlayPathRenderer {
        return MKMultiPolygonRenderer(multiPolygon: MKMultiPolygon(from: self))
    }
}

class GeometryProxy: NSObject, MKAnnotation, MKOverlay {
    let geometryID: NSManagedObjectID
    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect
    let title: String?
    let subtitle: String?

    init(
        geometryID: NSManagedObjectID,
        coordinate: CLLocationCoordinate2D,
        boundingMapRect: MKMapRect,
        title: String?,
        subtitle: String?
    ) {
        self.geometryID = geometryID
        self.coordinate = coordinate
        self.boundingMapRect = boundingMapRect
        self.title = title
        self.subtitle = subtitle
    }

    convenience init(geometry: Geometry) {
        self.init(
            geometryID: geometry.objectID,
            coordinate: geometry.coordinate,
            boundingMapRect: geometry.boundingMapRect ?? MKMapRect.null,
            title: geometry.title,
            subtitle: nil
        )
    }
}

extension Geometry {

    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(fromCoordinate: wrapped!.baseInfo.coordinate)
    }

    public var boundingMapRect: MKMapRect? {
        if let bb =  wrapped?.baseInfo.boundingBox {
            return MKMapRect(fromBox: bb)
        } else {
            return nil
        }
    }

    var betterBox: MKMapRect {
        guard let bbox = wrapped?.baseInfo.boundingBox else {
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
        return (wrapped?.shape as? Rendererable)?.makeRenderer()
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
