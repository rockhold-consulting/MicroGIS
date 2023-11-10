//
//  GeorgLayer.swift
//  Georg
//
//  Created by Michael Rockhold on 11/8/23.
//

import Foundation
import CoreData
import MapKit

extension GeorgLayer {
    
    convenience init(context: NSManagedObjectContext, zindex: Int) {
        self.init(context: context)
        self.zindex = Int16(zindex)
    }
    
    public class func makeLayer(dataURL: URL?, context: NSManagedObjectContext) throws {
        
        guard let dataURL = dataURL else {
            // TODO: throw something
            return
        }
        let decoder = MKGeoJSONDecoder()

        do {
            let countOfLayers = try context.count(for: GeorgLayer.fetchRequest())
            let layer = GeorgLayer(context: context, zindex: countOfLayers)
            
            let data = try Data(contentsOf: dataURL)
            
            for geoObject in try decoder.decode(data) {
                switch geoObject {
                case let feature as MKGeoJSONFeature:
                    try layer.add(feature: feature, context: context)
                    
                case let shape as MKShape:
                    try layer.add(shape: shape, context: context)
                    
                default:
                    break;
                }
            }
            
            try context.save()
        }
        catch {
            // TODO handle by removing the layer we just created
            throw error
        }
    }
    
    func add(feature: MKGeoJSONFeature, context ctx: NSManagedObjectContext) throws {
        do {
            let managedFeature = GeorgGeoFeature(context: ctx)
            managedFeature.layer = self
            self.addToFeatures(managedFeature)
            
            try ctx.save()

            for shape in feature.geometry {
                try managedFeature.add(shape: shape, context: ctx)
            }
            try ctx.save()
        }
        catch {
            throw error
        }
    }
        
}

