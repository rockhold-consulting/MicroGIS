//
//  GeoLayer.swift
//  Georg
//
//  Created by Michael Rockhold on 11/8/23.
//

import Foundation
import CoreData
import MapKit

@objc(GeoLayer)
public class GeoLayer: NSManagedObject {

    @objc dynamic var children: [Node]? {
        guard let kids = self.features?.allObjects as? [Node] else {
            return nil
        }
        return kids.count > 0 ? kids : nil
    }
    
    @objc dynamic var isLeaf: Bool { return false }

    var title: String? { return "Layer \(zindex)" }
    
    var identifier: String? { return "\(objectID)" }
    
    var isSpecialGroup: Bool { return true }
    
    var icon: NSImage {
        return NSImage(systemSymbolName: "square.3.layers.3d", accessibilityDescription: "layer icon")!
    }
    
    var canChange: Bool { return false }
    
    var canAddTo: Bool { return false }

}

extension GeoLayer {
    
    convenience init(context: NSManagedObjectContext, zindex: Int) {
        self.init(context: context)
        self.zindex = Int16(zindex)
    }
    
    
    func add(mkGeoObject: MKGeoJSONObject, geometryFactory: GeometryFactory, context ctx: NSManagedObjectContext) throws {
        
        switch mkGeoObject {
            
        case let mkFeature as MKGeoJSONFeature:
            let feature = GeoFeature(context: ctx, layer: self, geoJSONFeature: mkFeature)
            
            for shape in mkFeature.geometry {
                switch shape {
                case let annotation as MKPointAnnotation:
                    _ = GeoOverlay(context: ctx, layer: nil, feature: feature,
                                   geometry: GeoPoint(pointAnnotation: annotation))

                case let overlay as MKOverlay:
                    if let geometry = geometryFactory.createGeometry(from: overlay) {
                        _ = GeoOverlay(context: ctx, layer: nil,
                                       feature: feature,
                                       geometry: geometry)
                    }
                
                default:
                    break
                }
            }
               
        case let annotation as MKPointAnnotation:
            _ = GeoOverlay(context: ctx, 
                           layer: nil,
                           feature: nil,
                           geometry: GeoPoint(pointAnnotation: annotation))

        case let overlay as MKOverlay:
            if let geometry = geometryFactory.createGeometry(from: overlay) {
                _ = GeoOverlay(context: ctx, layer: nil, feature: nil, geometry: geometry)
            }
            
        default:
            break
        }
    }
}
