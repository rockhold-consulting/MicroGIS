//
//  GeoShapeWrapper.swift
//  Georg
//
//  Created by Michael Rockhold on 6/22/24.
//

import Foundation
import BinaryCodable

@objc
public class GeoShapeWrapper: NSObject, NSSecureCoding {

    static var encoder = BinaryEncoder()
    static var decoder = BinaryDecoder()

    let shape: GeoShape

    init(shape: GeoShape) {
        self.shape = shape
        super.init()
    }

    public static var supportsSecureCoding: Bool = true

    enum CodingKeys: String {
        case shapeCode
        case shape
    }

    public required init?(coder: NSCoder) {
        let rawShapeCode = coder.decodeInt32(forKey: CodingKeys.shapeCode.rawValue)
        let shapeCode = GeoShape.GeoShapeType(rawValue: rawShapeCode)!
        shape = Self.decodeShape(shapeCode: shapeCode, shapeData: coder.decodeObject(of: NSData.self, forKey: CodingKeys.shape.rawValue)! as Data)!
        super.init()
    }

    public func encode(with coder: NSCoder) {
        do {
            coder.encode(self.shape.shapeCode.rawValue, forKey: CodingKeys.shapeCode.rawValue)
            let shapeData = try GeoShapeWrapper.encoder.encode(self.shape)
            coder.encode(shapeData, forKey: CodingKeys.shape.rawValue)
        } catch {
            fatalError()
        }
    }

    static func decodeShape(shapeCode: GeoShape.GeoShapeType, shapeData: Data) -> GeoShape? {
        do {
            switch shapeCode {
            case .Point:
                return try decoder.decode(GeoPoint.self, from: shapeData)
            case .Multipoint:
                return try decoder.decode(GeoMultipoint.self, from: shapeData)
            case .Polyline:
                return try decoder.decode(GeoPolyline.self, from: shapeData)
            case .GeodesicPolyline:
                return try decoder.decode(GeoGeodesicPolyline.self, from: shapeData)
            case .Polygon:
                return try decoder.decode(GeoPolygon.self, from: shapeData)
            case .MultiPolyline:
                return try decoder.decode(GeoMultiPolyline.self, from: shapeData)
            case .MultiPolygon:
                return try decoder.decode(GeoMultiPolygon.self, from: shapeData)
            case .Circle:
                return try decoder.decode(GeoCircle.self, from: shapeData)
            default:
                // TODO: log a message
                return nil
            }
        } catch {
            fatalError()
        }
    }
}
