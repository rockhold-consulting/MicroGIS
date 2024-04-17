//
//  CoreDataGeoObjectCreator.swift
//  Georg
//
//  Created by Michael Rockhold on 3/25/24.
//

import Foundation
import CoreData
import BinaryCodable

class CoreDataGeoObjectCreator: GeoObjectCreator {

    private let importContext: NSManagedObjectContext
    private let encoder = BinaryEncoder()

    init(importContext: NSManagedObjectContext) {
        self.importContext = importContext
    }

    func createFeature(
        parent: GeoObjectParent,
        featureID: String,
        properties: FeatureProperties? = nil
    ) -> FeatureLike {
        let feature = Feature(
            context: self.importContext,
            featureID: featureID,
            properties: properties
        )
        parent.add(child: feature)
        return feature
    }


    func createAnnotationGeometry(
        coordinate: Geometry.Coordinate3D,
        title: String?,
        subtitle: String?,
        parent: GeoObjectParent
    ) {
        let geometry = Geometry(
            ctx: importContext,
            coordinate: coordinate,
            boundingBox: nil,
            title: title,
            subtitle: subtitle,
            shape: GeoPoint(coordinate: coordinate)
        )
        parent.add(child: geometry)
    }

    func createOverlayGeometry(
        coordinate: Geometry.Coordinate3D,
        boundingBox: Geometry.MapBox,
        shape: GeoShape,
        parent: GeoObjectParent
    ) {
        let geometry = Geometry(
            ctx: importContext,
            coordinate: coordinate,
            boundingBox: boundingBox,
            title: nil,
            subtitle: nil,
            shape: shape
        )
        parent.add(child: geometry)
    }

    func createLayer(name: String, importDate: Date) -> LayerLike {
        return Layer(ctx: importContext, name: name, importDate: importDate)
    }

    func createLayer(fileURL: URL) -> LayerLike {
        let name = fileURL.lastPathComponent
        return self.createLayer(name: name.isEmpty ? "Imported Layer" : name, importDate: .now)
    }
}

