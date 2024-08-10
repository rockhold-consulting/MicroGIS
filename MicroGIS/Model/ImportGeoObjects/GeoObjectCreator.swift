//
//  GeoObjectCreator.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 3/22/24.
//

import Foundation

public protocol GeoObjectLike {}

public protocol FeatureCollectionLike: GeoObjectLike {}

public protocol FeatureLike: GeoObjectLike {}

public protocol GeometryLike: GeoObjectLike {}

public protocol GeoObjectCreator {

    func createFeature(
        featureID: String?,
        properties: FeatureProperties?,
        parent: FeatureCollectionLike
    ) -> FeatureLike

    func createAnnotationGeometry(
        center: Coordinate3D,
        parent: FeatureLike
    ) -> GeometryLike

    func createOverlayGeometry(
        center: Coordinate3D,
        boundingVolume: Geometry.BoundingVolume,
        shape: GeoShape,
        parent: FeatureLike
    ) -> GeometryLike
}
