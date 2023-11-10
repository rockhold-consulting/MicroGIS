//
//  GeorgAnnotation.swift
//  Georg
//
//  Created by Michael Rockhold on 11/5/23.
//

import Foundation
import CoreLocation
import MapKit

extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: CodingKey {
        case latitude
        case longitude
    }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try values.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try values.decode(CLLocationDegrees.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}

extension GeorgAnnotation: MKAnnotation {
    
    public var coordinate: CLLocationCoordinate2D {
        get {
            return coordinateObj!.coordinate
        }
    }
    public convenience init(context: NSManagedObjectContext, annotation: MKAnnotation) {
        self.init(context: context)
        coordinateObj = GeorgCoordinate(context:context, coordinate: annotation.coordinate)
        title = annotation.title ?? nil
        subtitle = annotation.subtitle ?? nil
    }
}
