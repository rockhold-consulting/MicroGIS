//
//  GeoObject.swift
//  Georg
//
//  Created by Michael Rockhold on 11/10/23.
//

import Foundation
import CoreLocation
import MapKit

public class GeoObject: NSObject, MKAnnotation, NSSecureCoding {
    
    public let coordinate: CLLocationCoordinate2D
    public let title: String?
    public let subtitle: String?
    
    init(coordinate c: CLLocationCoordinate2D, title t: String? = nil, subtitle st: String? = nil) {
        self.coordinate = c
        self.title = t ?? nil
        self.subtitle = st ?? nil
        super.init()
    }

    // NSSecureCoding
    public class var supportsSecureCoding: Bool { true }

    // NSCoding
    enum CodingKeys: String, CodingKey {
        case coordinate = "geoobject_coordinate"
        case title = "geoobject_title"
        case subtitle = "geoobject_subtitle"
    }

    public required init?(coder: NSCoder) {
        let geocoordinate = coder.decodeObject(of: GeoCoordinate.self, 
                                               forKey: CodingKeys.coordinate.rawValue)!
        coordinate = geocoordinate.locationCoordinate
        title = coder.decodeObject(of: NSString.self,  forKey: CodingKeys.title.rawValue) as String?
        subtitle = coder.decodeObject(of: NSString.self, forKey: CodingKeys.subtitle.rawValue) as String?
        super.init()
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(coordinate.geocoordinate, forKey: CodingKeys.coordinate.rawValue)
        coder.encode(title, forKey: CodingKeys.title.rawValue)
        coder.encode(subtitle, forKey: CodingKeys.subtitle.rawValue)
    }
}
