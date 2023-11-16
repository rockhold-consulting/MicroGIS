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
    
    public class func makeLayer(dataURL: URL?, context: NSManagedObjectContext) throws {
        
        guard let dataURL = dataURL else {
            // TODO: throw something
            return
        }
        let decoder = MKGeoJSONDecoder()
        let geoObjectFactory = GeoObjectFactory()
        
        do {
            let countOfLayers = try context.count(for: GeoLayer.fetchRequest())
            let layer = GeoLayer(context: context, zindex: countOfLayers)
            
            for mkGeoObject in try decoder.decode(try Data(contentsOf: dataURL)) {
                try layer.add(mkGeoObject: mkGeoObject, geoObjectFactory: geoObjectFactory, context: context)
            }
        }
        catch {
            // TODO handle by removing the layer we just created
            throw error
        }
    }
    
    func add(mkGeoObject: MKGeoJSONObject, geoObjectFactory: GeoObjectFactory, context ctx: NSManagedObjectContext) throws {
        
        switch mkGeoObject {
            
        case let mkFeature as MKGeoJSONFeature:
            let feature = GeoFeature(context: ctx, owner: self) // metadata?
            
            for shape in mkFeature.geometry {
                if let geoInfo = try geoObjectFactory.createGeoObject(from: shape) {
                    _ = GeoFeatureOverlay(context: ctx, owner: feature, geoInfo: GeoInfoWrapper(geoInfo: geoInfo))
                }
            }
                   
        case let overlay as MKOverlay:
            if let geoInfo = try geoObjectFactory.createGeoObject(from: overlay) {
                _ = GeoLayerOverlay(context: ctx, owner: self, geoInfo: GeoInfoWrapper(geoInfo: geoInfo))
            }
            
        case let annotation as MKAnnotation:
            if let geoInfo = try geoObjectFactory.createGeoObject(from: annotation) {
                _ = GeoLayerAnnotation(context: ctx, owner: self, geoInfo: GeoInfoWrapper(geoInfo: geoInfo))
            }
            
        default:
            break
        }
    }
}
