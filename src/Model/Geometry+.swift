//
//  Geometry+.swift
//  GeorgB
//
//  Created by Michael Rockhold on 3/21/24.
//

import Foundation
import CoreData
import BinaryCodable

struct GeoBaseInfo: Codable {
    let coordinate: Geometry.Coordinate3D
    let boundingBox: Geometry.MapBox?
}

public protocol GeoShape : Codable {
    var shapeCode: Geometry.GeoShapeType { get }
}

public struct GeoPoint: GeoShape {
    public var shapeCode: Geometry.GeoShapeType { get { .Point }}

    let coordinate: Geometry.Coordinate3D

    enum CodingKeys: Int, CodingKey {
        case coordinate = 11
    }

    public init(coordinate: Geometry.Coordinate3D) {
        self.coordinate = coordinate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coordinate = try container.decode(Geometry.Coordinate3D.self, forKey: .coordinate)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinate, forKey: .coordinate)
    }
}

struct GeoCircle: GeoShape {
    public var shapeCode: Geometry.GeoShapeType { get { .Circle }}

    let center: Geometry.Coordinate3D
    let radius: Double
    let depth: Double

    enum CodingKeys: Int, CodingKey {
        case center = 21
        case radius
        case depth
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        center = try container.decode(Geometry.Coordinate3D.self, forKey: .center)
        radius = try container.decode(Double.self, forKey: .radius)
        depth = try container.decode(Double.self, forKey: .depth)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(center, forKey: .center)
        try container.encode(radius, forKey: .radius)
        try container.encode(depth, forKey: .depth)
    }
}


struct GeoMultipoint: GeoShape {
    public var shapeCode: Geometry.GeoShapeType { get { .Multipoint }}

    let coordinates: [Geometry.Coordinate3D]

    enum CodingKeys: Int, CodingKey {
        case coordinates = 31
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coordinates = try container.decode([Geometry.Coordinate3D].self, forKey: .coordinates)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinates, forKey: .coordinates)
    }
}

struct GeoPolyline: GeoShape {
    public var shapeCode: Geometry.GeoShapeType { get { .Polyline }}

    let coordinates: [Geometry.Coordinate3D]

    enum CodingKeys: Int, CodingKey {
        case coordinates = 41
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coordinates = try container.decode([Geometry.Coordinate3D].self, forKey: .coordinates)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinates, forKey: .coordinates)
    }
}

struct GeoGeodesicPolyline: GeoShape {
    public var shapeCode: Geometry.GeoShapeType { get { .GeodesicPolyline }}

    let coordinates: [Geometry.Coordinate3D]

    enum CodingKeys: Int, CodingKey {
        case coordinates = 51
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coordinates = try container.decode([Geometry.Coordinate3D].self, forKey: .coordinates)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinates, forKey: .coordinates)
    }
}

struct GeoPolygon: GeoShape {
    public var shapeCode: Geometry.GeoShapeType { get { .Polygon }}

    let coordinates: [Geometry.Coordinate3D]
    let innerPolygons: [GeoPolygon]

    enum CodingKeys: Int, CodingKey {
        case coordinates = 61
        case innerPolygons
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coordinates = try container.decode([Geometry.Coordinate3D].self, forKey: .coordinates)
        innerPolygons = try container.decode([GeoPolygon].self, forKey: .innerPolygons)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(innerPolygons, forKey: .innerPolygons)
    }
}

struct GeoMultiPolygon: GeoShape {
    public var shapeCode: Geometry.GeoShapeType { get { .MultiPolygon }}

    let polygons: [GeoPolygon]

    enum CodingKeys: Int, CodingKey {
        case polygons = 71
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        polygons = try container.decode([GeoPolygon].self, forKey: .polygons)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(polygons, forKey: .polygons)
    }
}

struct GeoMultiPolyline: GeoShape {
    public var shapeCode: Geometry.GeoShapeType { get { .MultiPolyline }}

    let polylines: [GeoPolyline]

    enum CodingKeys: Int, CodingKey {
        case polylines = 81
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        polylines = try container.decode([GeoPolyline].self, forKey: .polylines)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(polylines, forKey: .polylines)
    }
}

public extension Geometry {
    enum GeoShapeType: Int32, Codable {
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

    struct MapBox : Codable, Hashable {
        let x: Double
        let y: Double
        let z: Double
        let width: Double
        let height: Double
        let depth: Double
    }

    struct Coordinate3D: Codable, Hashable {
        let latitude: Double
        let longitude: Double
        let altitude: Double

        init(latitude lat: Double = 0.0, longitude lng: Double = 0.0, altitude alt: Double = 0.0) {
            latitude = lat
            longitude = lng
            altitude = alt
        }
    }

    convenience init(ctx: NSManagedObjectContext,
                     coordinate c: Coordinate3D,
                     boundingBox bb: MapBox?,
                     title t: String?,
                     subtitle st: String?,
                     shape: GeoShape
    ) {
        self.init(context: ctx)
        title = t
        subtitle = st
        self.baseInfo = GeoBaseInfoWrapper(value: GeoBaseInfo(coordinate: c, boundingBox: bb))
        self.shape = GeoShapeWrapper(value: shape)
    }
}

public class GeoBaseInfoWrapper: NSObject, NSSecureCoding {
    let value: GeoBaseInfo

    init(value: GeoBaseInfo) {
        self.value = value
        super.init()
    }

    public static var supportsSecureCoding: Bool = true

    public required init?(coder: NSCoder) {
        do {
            let data = coder.decodeData()
            value = try BinaryDecoder().decode(GeoBaseInfo.self, from: data!)
        } catch {
            fatalError()
        }
    }

    public func encode(with coder: NSCoder) {
        do {
            let data = try BinaryEncoder().encode(self.value)
            return coder.encode(data)
        } catch {
            fatalError()
        }
    }
}

public class GeoShapeWrapper: NSObject, NSSecureCoding {

    let value: GeoShape

    init(value: GeoShape) {
        self.value = value
    }

    public static var supportsSecureCoding: Bool = true

    enum CodingKeys: String {
        case code
        case value
    }

    required public init(coder aDecoder: NSCoder) {
        let rawShapeCode = aDecoder.decodeInt32(forKey: CodingKeys.code.rawValue)
        let shapeCode = Geometry.GeoShapeType(rawValue: rawShapeCode)!
        value = GeoShapeWrapper.decodeShape(shapeCode: shapeCode, shapeData: aDecoder.decodeData()!)!
        super.init()
    }

    public func encode(with aCoder: NSCoder) {
        do {
            aCoder.encode(self.value.shapeCode.rawValue, forKey: CodingKeys.code.rawValue)
            let shapeData = try BinaryEncoder.encode(self.value)
            aCoder.encode(shapeData)
        } catch {
            fatalError()
        }
    }

    static func decodeShape(shapeCode: Geometry.GeoShapeType, shapeData: Data) -> GeoShape? {
        do {
            let bDecoder = BinaryDecoder()
            switch shapeCode {
            case .Point:
                return try bDecoder.decode(GeoPoint.self, from: shapeData)
            case .Multipoint:
                return try bDecoder.decode(GeoMultipoint.self, from: shapeData)
            case .Polyline:
                return try bDecoder.decode(GeoPolyline.self, from: shapeData)
            case .GeodesicPolyline:
                return try bDecoder.decode(GeoGeodesicPolyline.self, from: shapeData)
            case .Polygon:
                return try bDecoder.decode(GeoPolygon.self, from: shapeData)
            case .MultiPolyline:
                return try bDecoder.decode(GeoMultiPolyline.self, from: shapeData)
            case .MultiPolygon:
                return try bDecoder.decode(GeoMultiPolygon.self, from: shapeData)
            case .Circle:
                return try bDecoder.decode(GeoCircle.self, from: shapeData)
            default:
                // TODO: log a message
                return nil
            }
        } catch {
            fatalError()
        }
    }
}

extension Geometry: GeometryLike {

    var isPoint: Bool { self.shapeTypeCode == GeoShapeType.Point.rawValue }
    
    public func set(parent: GeoObjectParent) {
        if let p = parent as? Layer {
            self.parent = p
        }
        if let p = parent as? Feature {
            self.parent = p
        }
    }
}

@objc
class GeoShapeTransformer: NSSecureUnarchiveFromDataTransformer {
    override static var allowedTopLevelClasses: [AnyClass] { [GeoShapeWrapper.self] }

    static func register() {
        ValueTransformer.setValueTransformer(GeoShapeTransformer(),
                                             forName: NSValueTransformerName(String(describing: GeoShapeTransformer.self)))
    }
}

@objc
class GeoBaseInfoTransformer: NSSecureUnarchiveFromDataTransformer {
    override static var allowedTopLevelClasses: [AnyClass] { [GeoBaseInfoWrapper.self] }

    static func register() {
        ValueTransformer.setValueTransformer(GeoBaseInfoTransformer(),
                                             forName: NSValueTransformerName(String(describing: GeoBaseInfoTransformer.self)))
    }
}
