//
//  AbstractFeature.swift
//  Georg
//
//  Created by Michael Rockhold on 11/8/23.
//

import Foundation
import CoreLocation
import MapKit

extension ShapeOwner {
        
    func add(shape: MKShape, context ctx: NSManagedObjectContext) throws {
        do {
            switch shape {
            case let circle as MKCircle:
                let georgShape = GeorgCircle(context: ctx, circle: circle)
                georgShape.owner = self
                self.addToShapes(georgShape)
                
            case let polyline as MKPolyline:
                let georgShape = GeorgPolyline(context: ctx, polyline: polyline)
                georgShape.owner = self
                self.addToShapes(georgShape)
                
            case let geodesicPolyline as MKGeodesicPolyline:
                let georgShape = GeorgGeodesicPolyline(context: ctx, geodesicPolyline: geodesicPolyline)
                georgShape.owner = self
                self.addToShapes(georgShape)
                
            case let pointAnnotation as MKPointAnnotation:
                let georgShape = GeorgPointAnnotation(context: ctx, pointAnnotation: pointAnnotation)
                georgShape.owner = self
                self.addToShapes(georgShape)
                
            case let multiPolyline as MKMultiPolyline:
                let georgShape = GeorgMultiPolyline(context: ctx, multiPolyline: multiPolyline)
                georgShape.owner = self
                self.addToShapes(georgShape)
                
            case let multiPolygon as MKMultiPolygon:
                let georgShape = GeorgMultiPolygon(context: ctx, multiPolygon: multiPolygon)
                georgShape.owner = self
                self.addToShapes(georgShape)
                
            case let polygon as MKPolygon:
                let georgShape = GeorgPolygon(context: ctx, polygon: polygon)
                georgShape.owner = self
                self.addToShapes(georgShape)
                
            default:
                print("warning: unhandled class of decoded MKGeo shape \(shape)")
            }
            
            try ctx.save()
        }
        catch {
            throw error
        }
    }
    
}
