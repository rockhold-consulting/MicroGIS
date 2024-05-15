//
//  Geometry+.swift
//  GeorgB
//
//  Created by Michael Rockhold on 3/21/24.
//

import Foundation
import CoreData
import BinaryCodable

public struct GeoBaseInfo: Codable {
    let coordinate: Geometry.Coordinate3D
    let boundingBox: Geometry.MapBox?
}

public protocol GeoShape : Codable {
    var shapeCode: Geometry.GeoShapeType { get }
    var kindString: String { get }
    var icon: KitImage { get }
}

public struct GeoPoint: GeoShape {
    public var shapeCode: Geometry.GeoShapeType { get { .Point }}
    public var kindString: String { "Point" }
    public var icon: KitImage {
        return KitImage(systemSymbolName: "mappin.circle", accessibilityDescription: "Point icon")!
    }

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
    public var kindString: String { "Circle" }
    public var icon: KitImage {
        return KitImage(systemSymbolName: "smallcircle.circle", accessibilityDescription: "Circle icon")!
    }

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
    public var kindString: String { "MultiPoint" }
    public var icon: KitImage {
        return KitImage(systemSymbolName: "circle.dotted.circle", accessibilityDescription: "Multipoint icon")!
    }

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
    public var kindString: String { "Polyline" }
    public var icon: KitImage {
        return KitImage(systemSymbolName: "lines.measurement.horizontal", accessibilityDescription: "Polyline icon")!
    }

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
    public var kindString: String { "Geodesic Polyline" }
    public var icon: KitImage {
        return KitImage(systemSymbolName: "globe.desk", accessibilityDescription: "Geodesic Polyline icon")!
    }

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
    public var kindString: String { "Polygon" }
    public var icon: KitImage {
        return KitImage(systemSymbolName: "pentagon", accessibilityDescription: "Polygone icon")!
    }

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
        try container.encode(coordinates, forKey: .coordinates)
        try container.encode(innerPolygons, forKey: .innerPolygons)
    }
}

struct GeoMultiPolygon: GeoShape {
    public var shapeCode: Geometry.GeoShapeType { get { .MultiPolygon }}
    public var kindString: String { "MultiPolygon" }
    public var icon: KitImage {
        return KitImage(systemSymbolName: "platter.2.filled.ipad.landscape", accessibilityDescription: "MultiPolygon icon")!
    }

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
    public var kindString: String { "MultiPolyline" }
    public var icon: KitImage {
        return KitImage(systemSymbolName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left", accessibilityDescription: "MultiPolyline icon")!
    }

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
                     shape: GeoShape,
                     layerParent: Layer
    ) {
        self.init(context: ctx)
        self.wrapped = GeoWrapper(baseInfo: GeoBaseInfo(coordinate: c, boundingBox: bb), shape: shape)
        self.layerParent = layerParent
    }
    convenience init(ctx: NSManagedObjectContext,
                     coordinate c: Coordinate3D,
                     boundingBox bb: MapBox?,
                     shape: GeoShape,
                     featureParent: Feature
    ) {
        self.init(context: ctx)
        self.wrapped = GeoWrapper(baseInfo: GeoBaseInfo(coordinate: c, boundingBox: bb), shape: shape)
        self.featureParent = featureParent
    }
}

extension Geometry: ModelObject {

    var title: String? {
        get {
            GeometryFormatter().string(from: self)
        }
        set {
            // TODO: decide what to do about this
        }
    }

    var canRename: Bool { false }

    var identifier: NSObject { self.objectID }

    var isLeaf: Bool { true }

    var kidArray: [ModelObject]? { nil }

    var icon: KitImage {
        return wrapped?.shape.icon ?? KitImage(systemSymbolName: "mappin.and.ellipse", accessibilityDescription: "default geometry icon")!
    }
}

@objc
public class GeoWrapper: NSObject, NSSecureCoding {
    let baseInfo: GeoBaseInfo
    let shape: GeoShape

    init(baseInfo: GeoBaseInfo, shape: GeoShape) {
        self.baseInfo = baseInfo
        self.shape = shape
        super.init()
    }

    public static var supportsSecureCoding: Bool = true

    enum CodingKeys: String {
        case baseInfo
        case shapeCode
        case shape
    }

    public required init?(coder: NSCoder) {
        do {

            let data = coder.decodeObject(forKey: CodingKeys.baseInfo.rawValue) as! Data
            baseInfo = try BinaryDecoder().decode(GeoBaseInfo.self, from: data)

            let rawShapeCode = coder.decodeInt32(forKey: CodingKeys.shapeCode.rawValue)

            let shapeCode = Geometry.GeoShapeType(rawValue: rawShapeCode)!
            shape = Self.decodeShape(shapeCode: shapeCode, shapeData: coder.decodeObject(forKey: CodingKeys.shape.rawValue) as! Data)!

            super.init()
        } catch {
            fatalError()
        }
    }

    public func encode(with coder: NSCoder) {
        do {
            let data = try BinaryEncoder().encode(self.baseInfo)
            coder.encode(data, forKey: CodingKeys.baseInfo.rawValue)

            coder.encode(self.shape.shapeCode.rawValue, forKey: CodingKeys.shapeCode.rawValue)

            let shapeData = try BinaryEncoder.encode(self.shape)
            coder.encode(shapeData, forKey: CodingKeys.shape.rawValue)

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

extension Geometry {
    var isPoint: Bool { self.wrapped!.shape is GeoPoint }
}

class GeoWrapperTransformer: NSSecureUnarchiveFromDataTransformer {

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override class func transformedValueClass() -> AnyClass {
        return GeoWrapper.self
    }

    override class var allowedTopLevelClasses: [AnyClass] {
        return [GeoWrapper.self, NSData.self]
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            fatalError("Wrong data type: value must be a Data object; received \(type(of: value))")
        }
        return super.transformedValue(data)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let v = value as? GeoWrapper else {
            fatalError("Wrong data type: value must be a GeoWrapper object; received \(type(of: value))")
        }
        return super.reverseTransformedValue(v)
    }

    static let geoWrapperTransformerName = NSValueTransformerName(rawValue: "GeoWrapperTransformer")

    static func register() {
        ValueTransformer.setValueTransformer(GeoWrapperTransformer(),
                                             forName: geoWrapperTransformerName)
    }
}

//class GeoWrapperTransformer: NSSecureUnarchiveFromDataTransformer {
//
//    override class func allowsReverseTransformation() -> Bool {
//        return true
//    }
//
//    override class func transformedValueClass() -> AnyClass {
//        return GeoBaseInfoWrapper.self
//    }
//
//    override class var allowedTopLevelClasses: [AnyClass] {
//        return [GeoBaseInfoWrapper.self, NSData.self]
//    }
//
//    override func transformedValue(_ value: Any?) -> Any? {
//        guard let data = value as? Data else {
//            fatalError("Wrong data type: value must be a Data object; received \(type(of: value))")
//        }
//        return super.transformedValue(data)
//    }
//
//    override func reverseTransformedValue(_ value: Any?) -> Any? {
//        guard let v = value as? GeoBaseInfoWrapper else {
//            fatalError("Wrong data type: value must be a GeoBaseInfoWrapper object; received \(type(of: value))")
//        }
//        return super.reverseTransformedValue(v)
//    }
//
//    static let geoBaseInfoTransformerName = NSValueTransformerName(rawValue: "GeoBaseInfoTransformer")
//
//    static func register() {
//        ValueTransformer.setValueTransformer(GeoBaseInfoTransformer(),
//                                             forName: geoBaseInfoTransformerName)
//    }
//}
