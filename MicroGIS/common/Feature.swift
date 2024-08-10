//
//  Feature.swift
//  Georg
//
//  Created by Michael Rockhold on 11/8/23.
//

import Foundation
import CoreLocation
import MapKit



public class Feature: GeoObject {
    public typealias FeatureProperties = [String: Any]

    @Published public var featureID: String?
    @Published public var properties: FeatureProperties
    @Published public var geometries: [Geometry]

    init(featureID: String?,
         featureProperties: FeatureProperties?) {
        self.featureID = featureID
        self.properties = featureProperties == nil ? FeatureProperties() : featureProperties!
        self.geometries = [Geometry]()
        super.init()
    }

    override var icon: KitImage {
        if !geometries.isEmpty {
            return geometries[0].icon
        }
        else {
            return super.icon
        }
    }
    
    override public var description: String {
        return geometries.count == 1 ? geometries[0].description : featureID ?? "Unnamed Feature"
    }

    override public var children: [GeoObject]? {
        if geometries.count != 1 {
            return geometries as [GeoObject]
        } else {
            return nil
        }
    }

    enum CodingKeys: Int, CodingKey {
        case identifier = 11
        case featureID
        case properties
        case geometries
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        featureID = try container.decodeIfPresent(String.self, forKey: .featureID)
        geometries = try container.decode([Geometry].self, forKey: .geometries)
        let propertiesData = try container.decode(Data.self, forKey: .properties)
        properties = (try? JSONSerialization.jsonObject(with: propertiesData, options: .allowFragments) as? FeatureProperties) ?? FeatureProperties()
        try super.init(from: container.superDecoder())
    }

    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(geometries, forKey: .geometries)
        try container.encodeIfPresent(featureID, forKey: .featureID)
        let propertiesData = try JSONSerialization.data(withJSONObject: properties, options: [])
        try container.encode(propertiesData, forKey: .properties)
        try super.encode(to: container.superEncoder())
    }
}
