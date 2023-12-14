//
//  GeoInfoFactory.swift
//  Georg
//
//  Created by Michael Rockhold on 11/15/23.
//

import Foundation
import MapKit

class GeoInfoFactory {
        
    func createGeoInfo(from mkOverlay: MKOverlay) -> GeoObject? {
        switch mkOverlay {
        case let circle as MKCircle:
            return GeoCircle(circle: circle)

        case let polyline as MKPolyline:
            return GeoPolyline(polyline: polyline)

        case let geodesicPolyline as MKGeodesicPolyline:
            return GeoGeodesicPolyline(polyline: geodesicPolyline)

        case let multiPolyline as MKMultiPolyline:
            return GeoMultiPolyline(multiPolyline: multiPolyline)

        case let multiPolygon as MKMultiPolygon:
            return GeoMultiPolygon(multiPolygon: multiPolygon)

        case let polygon as MKPolygon:
            return GeoPolygon(polygon: polygon)

        default:
            print("warning: unhandled class of decoded MKGeo shape \(mkOverlay)")
            return nil
        }
    }
}
