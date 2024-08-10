//
//  GeometryBase.swift
//  Georg
//
//  Created by Michael Rockhold on 3/10/24.
//

import Foundation

public class GeometryBase: Codable {

    public struct MapRect : Codable, Hashable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }

    public struct Coordinate: Codable, Hashable {
        let latitude: Double
        let longitude: Double
        let altitude: Double

        init(latitude lat: Double = 0.0, longitude lng: Double = 0.0, altitude alt: Double = 0.0) {
            latitude = lat
            longitude = lng
            altitude = alt
        }
    }

    public let coord: Coordinate
    public let bBox: MapRect?
    @objc public var title: String?
    @objc public var subtitle: String?

    init(coordinate c: Coordinate,
         boundingBox bb: MapRect? = nil,
         title t: String? = nil,
         subtitle st: String? = nil) {

        coord = c
        bBox = bb
        title = t
        subtitle = st
        super.init()
    }

    enum CodingKeys: Int, CodingKey {
        case coordinate = 21
        case boundingBox
        case title
        case subtitle
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coord = try container.decode(Coordinate.self, forKey: .coordinate)
        bBox = try container.decodeIfPresent(MapRect.self, forKey: .boundingBox)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        try super.init(from: container.superDecoder())
    }

    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coord, forKey: .coordinate)
        try container.encodeIfPresent(bBox, forKey: .boundingBox)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try super.encode(to: container.superEncoder())
    }
}
