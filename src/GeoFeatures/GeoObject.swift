//
//  GeoObject.swift
//  Georg
//
//  Created by Michael Rockhold on 11/10/23.
//

import Foundation
import CoreLocation

public class GeoObject: Codable {
    
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    
    init(coordinate c: CLLocationCoordinate2D, title t: String? = nil, subtitle st: String? = nil) {
        self.coordinate = c
        self.title = t ?? nil
        self.subtitle = st ?? nil
    }

    private enum CodingKeys: String, CodingKey {
        case coordinate
        case title
        case subtitle
    }

    // Decodable
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        coordinate = try values.decode(CLLocationCoordinate2D.self, forKey: .coordinate)
        title = try? values.decode(String.self, forKey: .title)
        subtitle = try? values.decode(String.self, forKey: .subtitle)
    }
    
    // Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinate, forKey: .coordinate)
        if let t = title {
            try? container.encode(t, forKey: .title)
        }
        if let st = subtitle {
            try? container.encode(st, forKey: .subtitle)
        }
    }
}
