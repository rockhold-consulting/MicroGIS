//
//  GeoLayer.swift
//  Georg
//
//  Created by Michael Rockhold on 11/8/23.
//

import Foundation
import CoreData
import MapKit

extension GeoLayer {
    
    convenience init(context: NSManagedObjectContext, zindex: Int) {
        self.init(context: context)
        self.zindex = Int16(zindex)
    }
    
    
    func add(mkGeoObject: MKGeoJSONObject, geoInfoFactory: GeoInfoFactory, context ctx: NSManagedObjectContext) throws {
        
        switch mkGeoObject {
            
        case let mkFeature as MKGeoJSONFeature:
            let feature = GeoFeature(context: ctx, layer: self, geoJSONFeature: mkFeature)
            
            for shape in mkFeature.geometry {
                switch shape {
                case let annotation as MKPointAnnotation:
                    _ = GeoOverlay(context: ctx, layer: nil, feature: feature, geoInfo: GeoPointAnnotation(pointAnnotation: annotation))

                case let overlay as MKOverlay:
                    if let geoInfo = geoInfoFactory.createGeoInfo(from: overlay) {
                        _ = GeoOverlay(context: ctx, layer: nil, feature: feature, geoInfo: geoInfo)
                    }
                
                default:
                    break
                }
            }
               
        case let annotation as MKPointAnnotation:
            _ = GeoOverlay(context: ctx, layer: nil, feature: nil, geoInfo: GeoPointAnnotation(pointAnnotation: annotation))

        case let overlay as MKOverlay:
            if let geoInfo = geoInfoFactory.createGeoInfo(from: overlay) {
                _ = GeoOverlay(context: ctx, layer: nil, feature: nil, geoInfo: geoInfo)
            }
            
        default:
            break
        }
    }
}
