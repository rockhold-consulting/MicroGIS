//
//  GeoMultiPoint.swift
//  Georg
//
//  Created by Michael Rockhold on 11/10/23.
//

import Foundation
import CoreLocation
import MapKit

extension MKMultiPoint {
    var coordinates: [CLLocationCoordinate2D] {
        
        var coords = [CLLocationCoordinate2D]()
        let points = self.points()
        for p in 0..<self.pointCount {
            coords.append(points[p].coordinate)
        }
        return coords
    }
}

public class GeoMultiPoint: GeoOverlayShape {
    
    let coordinates: [CLLocationCoordinate2D]
    
    init(coordinate c: CLLocationCoordinate2D,
         boundingMapRect bmr: MKMapRect,
         coordinates cs: [CLLocationCoordinate2D],
         title t: String? = nil,
         subtitle st: String? = nil) {
        
        coordinates = cs
        super.init(coordinate: c, boundingMapRect: bmr, title: t, subtitle: st)
    }
    
    // NSCoding/NSSecureCoding
    public override class var supportsSecureCoding: Bool { true }
    
    private enum CodingKeys: String, CodingKey {
        case coordinates = "geomultipoint_coordinates"
    }

    public required init?(coder: NSCoder) {
        if let coordinateArray = coder.decodeArrayOfObjects(ofClass: GeoCoordinate.self,
                                                            forKey: CodingKeys.coordinates.rawValue) {
            coordinates = coordinateArray.map { $0.locationCoordinate }
        }
        else {
            coordinates = [CLLocationCoordinate2D]()
        }
        super.init(coder: coder)
    }
    
    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        var coordinateArray = NSMutableArray()
        coordinates.forEach {
            coordinateArray.add($0.geocoordinate)
        }
        coder.encode(coordinateArray, forKey: CodingKeys.coordinates.rawValue)
    }
}
