//
//  Geometry.swift
//  Georg
//
//  Created by Michael Rockhold on 11/15/23.
//

import Foundation
#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#endif

protocol GeoShape : Codable, Equatable {
    func typeCode() -> Geometry.GeoShapeType
}

struct GeoPoint: GeoShape {
    static let typeCode = Geometry.GeoShapeType.Point
    func typeCode() -> Geometry.GeoShapeType { return Self.typeCode }
    let coordinate: Geometry.Coordinate3D
}

struct GeoPolyline: GeoShape {
    static let typeCode = Geometry.GeoShapeType.Polyline
    func typeCode() -> Geometry.GeoShapeType { return Self.typeCode }
    let coordinates: [Geometry.Coordinate3D]
}

struct GeoGeodesicPolyline: GeoShape {
    static let typeCode = Geometry.GeoShapeType.GeodesicPolyline
    func typeCode() -> Geometry.GeoShapeType { return Self.typeCode }
    let coordinates: [Geometry.Coordinate3D]
}

struct GeoPolygon: GeoShape {
    static let typeCode = Geometry.GeoShapeType.Polygon
    func typeCode() -> Geometry.GeoShapeType { return Self.typeCode }
    let coordinates: [Geometry.Coordinate3D]
    let innerPolygons: [GeoPolygon]
}

struct GeoMultiPolygon: GeoShape {
    static let typeCode = Geometry.GeoShapeType.MultiPolygon
    func typeCode() -> Geometry.GeoShapeType { return Self.typeCode }
    let polygons: [GeoPolygon]
}

struct GeoMultiPolyline: GeoShape {
    static let typeCode = Geometry.GeoShapeType.MultiPolyline
    func typeCode() -> Geometry.GeoShapeType { return Self.typeCode }
    let polylines: [GeoPolyline]
}

public class Geometry : GeometryBase {
    enum GeoShapeType: Int {
        case Point = 1
        case Polyline
        case GeodesicPolyline
        case Circle
        case Polygon
        case MultiPolyline
        case MultiPolygon
    }

    weak var owner: Feature? = nil
    let shape: any GeoShape

    init(coordinate c: Geometry.Coordinate3D,
         boundingBox bb: GeometryBase.MapRect? = nil,
         title t: String? = nil,
         subtitle st: String? = nil,
         shape s: any GeoShape) {

        shape = s
        super.init(coordinate: c, 
                   boundingBox: bb,
                   title: t,
                   subtitle: st)
    }

    override public var description: String {
        if let t = title {
            return "\(shape.typeCode()) \(t))"
        } else {
            return "\(shape.typeCode()) at latitude \(coord.latitude), longitude \(coord.longitude)"
        }
    }

    override var icon: KitImage {
#if os(macOS)
        return NSImage(systemSymbolName: "mappin.square", accessibilityDescription: "map geometry icon")!
#elseif os(iOS)
        return UIImage(systemName: "mappin.square")!
#endif
    }

    enum CodingKeys: Int, CodingKey {
        case shapeType =  31
        case shape
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let geoDataTypeValue = try container.decode(Int.self, forKey: .shapeType)
        guard let typeCode = GeoShapeType(rawValue: geoDataTypeValue) else {
            fatalError("unknown GeoShapeType")
        }
        switch typeCode {
        case .Point:
            shape = try container.decode(GeoPoint.self, forKey: .shape)
        case .Polyline:
            shape = try container.decode(GeoPolyline.self, forKey: .shape)
        case .GeodesicPolyline:
            shape = try container.decode(GeoGeodesicPolyline.self, forKey: .shape)
        case .Polygon:
            shape = try container.decode(GeoPolygon.self, forKey: .shape)
        case .MultiPolygon:
            shape = try container.decode(GeoMultiPolygon.self, forKey: .shape)
        case .MultiPolyline:
            shape = try container.decode(GeoMultiPolyline.self, forKey: .shape)

        default:
            fatalError("unsupported shape")
        }
        try super.init(from: container.superDecoder())
    }

    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(shape.typeCode().rawValue, forKey: .shapeType)
        try container.encode(shape, forKey: .shape)
        try super.encode(to: container.superEncoder())
    }

}
