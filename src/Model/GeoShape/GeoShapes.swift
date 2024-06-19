//
//  GeoShapes.swift
//  Georg
//
//  Created by Michael Rockhold on 6/22/24.
//

import Foundation

public class GeoShape: Codable {

    public enum GeoShapeType: Int32, Codable {
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

    public private (set) var shapeCode: GeoShape.GeoShapeType = .Invalid
    public private (set) var iconSymbolName: String = ""
}

public class GeoPoint: GeoShape {

    public override var shapeCode: GeoShape.GeoShapeType { .Point }
    public override var iconSymbolName: String { "mappin.circle" }

    let center: Coordinate3D

    public init(center: Coordinate3D) {
        self.center = center
        super.init()
    }

    enum CodingKeys: Int, CodingKey {
        case center = 301
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        center = try container.decode(Coordinate3D.self, forKey: .center)
        super.init()
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(center, forKey: .center)
    }
}

class GeoCircle: GeoPoint {
    public override var shapeCode: GeoShapeType { get { .Circle }}
    public override var iconSymbolName: String { "smallcircle.circle" }

    let radius: Double
    let depth: Double

    enum CodingKeys: Int, CodingKey {
        case radius = 302
        case depth
    }

    public init(center: Coordinate3D, radius: Double, depth: Double = 0.0) {
        self.radius = radius
        self.depth = depth
        super.init(center: center)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        radius = try container.decode(Double.self, forKey: .radius)
        depth = try container.decode(Double.self, forKey: .depth)
        try super.init(from: container.superDecoder())
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try super.encode(to: container.superEncoder())
        try container.encode(radius, forKey: .radius)
        try container.encode(depth, forKey: .depth)
    }
}


class GeoMultipoint: GeoShape {
    public override var shapeCode: GeoShapeType { get { .Multipoint }}
    public override var iconSymbolName: String { "circle.dotted.circle" }

    let coordinates: [Coordinate3D]

    enum CodingKeys: Int, CodingKey {
        case coordinates = 304
    }

    public init(coordinates: [Coordinate3D]) {
        self.coordinates = coordinates
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coordinates = try container.decode([Coordinate3D].self, forKey: .coordinates)
        super.init()
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinates, forKey: .coordinates)
    }
}

class GeoPolyline: GeoMultipoint {
    public override var shapeCode: GeoShapeType { get { .Polyline }}
    public override var iconSymbolName: String { "lines.measurement.horizontal" }
}

class GeoGeodesicPolyline: GeoPolyline {
    public override var shapeCode: GeoShapeType { get { .GeodesicPolyline }}
    public override var iconSymbolName: String { "globe.desk" }
}

class GeoPolygon: GeoMultipoint {
    public override var shapeCode: GeoShapeType { get { .Polygon }}
    public override var iconSymbolName: String { "pentagon" }

    let innerPolygons: [GeoPolygon]

    public init(coordinates: [Coordinate3D], innerPolygons: [GeoPolygon] = [GeoPolygon]()) {
        self.innerPolygons = innerPolygons
        super.init(coordinates: coordinates)
    }

    enum CodingKeys: Int, CodingKey {
        case innerPolygons = 305
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        innerPolygons = try container.decode([GeoPolygon].self, forKey: .innerPolygons)
        try super.init(from: container.superDecoder())
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try super.encode(to: container.superEncoder())
        try container.encode(innerPolygons, forKey: .innerPolygons)
    }
}

class GeoMultiPolygon: GeoShape {
    public override var shapeCode: GeoShapeType { get { .MultiPolygon }}
    public override var iconSymbolName: String { "platter.2.filled.ipad.landscape" }

    let polygons: [GeoPolygon]

    enum CodingKeys: Int, CodingKey {
        case polygons = 306
    }

    public init(polygons: [GeoPolygon]) {
        self.polygons = polygons
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        polygons = try container.decode([GeoPolygon].self, forKey: .polygons)
        super.init()
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(polygons, forKey: .polygons)
    }
}

class GeoMultiPolyline: GeoShape {
    public override var shapeCode: GeoShapeType { get { .MultiPolyline }}
    public override var iconSymbolName: String { "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left" }

    let polylines: [GeoPolyline]

    enum CodingKeys: Int, CodingKey {
        case polylines = 307
    }

    public init(polylines: [GeoPolyline]) {
        self.polylines = polylines
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        polylines = try container.decode([GeoPolyline].self, forKey: .polylines)
        super.init()
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(polylines, forKey: .polylines)
    }
}
