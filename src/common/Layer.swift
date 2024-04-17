//
//  Layer.swift
//  Georg
//
//  Created by Michael Rockhold on 11/8/23.
//

import Foundation
#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#endif

public class Layer: GeoObject {

    public var importDate: Date
    @Published public var name: String
    @Published public var features = [Feature]()
    @Published public var geometries = [Geometry]()

    override public var description: String {
        return "\(name) created at \(DateFormatter().string(from: importDate))"
    }

    override public var children: [GeoObject]? {
        return [features as [GeoObject], geometries as [GeoObject]].flatten() as [GeoObject]
    }

    init(name n: String, importDate d: Date) {
        name = n
        importDate = d
        super.init()
    }

    override var icon: KitImage {
#if os(macOS)
        return KitImage(systemSymbolName: "square.3.layers.3d", accessibilityDescription: "layer icon")!
#elseif os(iOS)
        return UIImage(systemName: "square.3.layers.3d")!
#endif
    }
    
    enum CodingKeys: Int, CodingKey {
        case importDate = 1
        case name
        case origin
        case features
        case geometries
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        importDate = try container.decode(Date.self, forKey: .importDate)
        name = try container.decode(String.self, forKey: .name)
        features = try container.decode([Feature].self, forKey: .features)
        geometries = try container.decode([Geometry].self, forKey: .geometries)
        try super.init(from: container.superDecoder())
    }

    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(importDate, forKey: .importDate)
        try container.encode(name, forKey: .name)
        try container.encode(features, forKey: .features)
        try container.encode(geometries, forKey: .geometries)
        try super.encode(to: container.superEncoder())
    }
}


public extension Array where Element: Collection {

    func flatten() -> [Element.Element] {
        return reduce([], +)
    }
}
