//
//  CoreDataGeoObjectCreator.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 3/25/24.
//

import Foundation
import CoreData
import BinaryCodable

extension FeatureCollection: FeatureCollectionLike {}
extension Feature: FeatureLike {}
extension Geometry: GeometryLike {}

class CoreDataGeoObjectCreator: GeoObjectCreator {

    private let importContext: NSManagedObjectContext

    init(importContext: NSManagedObjectContext) {
        self.importContext = importContext
    }

    func createFeature(featureID: String?, properties: FeatureProperties?, parent: FeatureCollectionLike) -> FeatureLike {
        return Feature(
            context: self.importContext,
            featureID: featureID,
            properties: properties,
            parent: parent as! FeatureCollection)
    }

    func createAnnotationGeometry(center: Coordinate3D,
                                  parent: FeatureLike) -> GeometryLike {

        return Geometry(
            context: importContext,
            center: center,
            boundingVolume: Geometry.BoundingVolume(),
            shape: GeoPoint(center: center),
            parent: parent as! Feature)
    }

    func createOverlayGeometry(
        center: Coordinate3D,
        boundingVolume: Geometry.BoundingVolume,
        shape: GeoShape,
        parent: FeatureLike) -> GeometryLike {

            return Geometry(
                context: importContext,
                center: center,
                boundingVolume: boundingVolume,
                shape: shape,
                parent: parent as! Feature)
        }
}

