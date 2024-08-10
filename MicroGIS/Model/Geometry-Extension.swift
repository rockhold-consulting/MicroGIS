//
//  Geometry-Extension.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 3/21/24.
//

import Foundation
import CoreData
import CoreLocation

public typealias GeometryID = NSManagedObjectID

@objc(Geometry)
public class Geometry: NSManagedObject {

    public enum GeoShapeType: Int16, Codable {
        case Invalid = 0
        case Point
        case Multipoint
        case Polyline
        case GeodesicPolyline
        case Circle
        case Polygon
        case MultiPolyline
        case MultiPolygon
    }

    public class var shapeCode: Geometry.GeoShapeType { .Invalid }
    public class var iconName: String { "mappin.and.ellipse" }

    convenience init(context: NSManagedObjectContext,
                     latitude: Double,
                     longitude: Double) {
        self.init(context: context)
        self.centerLatitude = latitude
        self.centerLongitude = longitude
        self.rawShapeCode = Self.shapeCode.rawValue
    }

    convenience init(context: NSManagedObjectContext,
                     center: CLLocationCoordinate2D) {
        self.init(context: context, 
                  latitude: center.latitude,
                  longitude: center.longitude)
    }

    public var centerIsMovable: Bool { return false }
}

@objc(MGPoint)
public class MGPoint: Geometry {
    public override class var shapeCode: Geometry.GeoShapeType { .Point }
    public override class var iconName: String { "mappin.circle" }

    public override var centerIsMovable: Bool { return true }
}

@objc(MGCircle)
public class MGCircle: Geometry {
    public override class var shapeCode: GeoShapeType { get { .Circle }}
    public override class var iconName: String { "smallcircle.circle" }

    public convenience init(context:NSManagedObjectContext,
                            center: CLLocationCoordinate2D,
                            radius: Double) {
        self.init(context: context, center: center)
        self.radius = radius
    }

    public override var centerIsMovable: Bool { return true }
}

@objc(MGMultipoint)
public class MGMultipoint: Geometry {
    public override class var shapeCode: GeoShapeType { get { .Multipoint }}
    public override class var iconName: String { "circle.dotted.circle" }

    public convenience init(context:NSManagedObjectContext, center: CLLocationCoordinate2D, coordinates: [CLLocationCoordinate2D]) {
        self.init(context: context, center: center)
        let pointsSet = NSOrderedSet(array: coordinates.map({ coordinate in
            MGCoordinate(context: context, coordinate: coordinate)
        }))
        self.addToPoints(pointsSet)
    }
}

@objc(MGPolyline)
public class MGPolyline: MGMultipoint {
    public override class var shapeCode: GeoShapeType { get { .Polyline }}
    public override class var iconName: String { "lines.measurement.horizontal" }
}

@objc(MGGeodesicPolyline)
public class MGGeodesicPolyline: MGPolyline {
    public override class var shapeCode: GeoShapeType { get { .GeodesicPolyline }}
    public override class var iconName: String { "wifi" }
}

@objc(MGPolygon)
public class MGPolygon: MGMultipoint {
    public override class var shapeCode: GeoShapeType { get { .Polygon }}
    public override class var iconName: String { "pentagon" }

    public convenience init(context:NSManagedObjectContext,
                center: CLLocationCoordinate2D,
                coordinates: [CLLocationCoordinate2D],
                innerPolygons: [MGPolygon] = [MGPolygon]()) {
        self.init(context: context, center: center, coordinates: coordinates)
        self.addToInnerPolygons(NSSet(array: innerPolygons))
    }
}

@objc(MGMultiPolygon)
public class MGMultiPolygon: Geometry {
    public override class var shapeCode: GeoShapeType { get { .MultiPolygon }}
    public override class var iconName: String { "platter.2.filled.ipad.landscape" }

    public convenience init(context:NSManagedObjectContext,
                center: CLLocationCoordinate2D,
                polygons: [MGPolygon]) {
        self.init(context: context, center: center)
        self.addToPolygons(NSSet(array: polygons))
    }
}

@objc(MGMultiPolyline)
public class MGMultiPolyline: Geometry {
    public override class var shapeCode: GeoShapeType { get { .MultiPolyline }}
    public override class var iconName: String { "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left" }

    public convenience init(context:NSManagedObjectContext,
                center: CLLocationCoordinate2D,
                polylines: [MGPolyline]) {
        self.init(context: context, center: center)
        self.addToPolylines(NSSet(array: polylines))
    }
}


extension Geometry {
    var coordString: String {
        return Self.coordFormatter.string(from: center)
    }
}

extension Geometry { // conveniences

    static let coordFormatter = CoordinateFormatter(style: .Decimal)

    var parentID: NSManagedObjectID? { self.feature?.objectID }

    var shortName: String { self.objectID.shortName }

    var featureShortName: String { self.parentID?.shortName ?? "?" }

    public var iconSymbolName: String { Self.iconName }

    var isPoint: Bool { self is MGPoint }

    var isPolyline: Bool { self is MGPolyline }

    var isMultiPolyline: Bool { self is MGMultiPolyline }

    var isPolylineish: Bool { isPolyline || isMultiPolyline }
}
