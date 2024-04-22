//
//  GeoObjectCreator.swift
//  Georg
//
//  Created by Michael Rockhold on 3/22/24.
//

import Foundation

public protocol GeoObjectLike {}

public protocol GeometryParent: GeoObjectLike {}

public protocol LayerLike: GeoObjectLike, GeometryParent {}

public protocol FeatureLike: GeoObjectLike, GeometryParent {}

public protocol GeometryLike: GeoObjectLike {}

public protocol GeoObjectCreator {

    func createLayer(name: String, importDate: Date) -> LayerLike

    func createFeature(
        featureID: String?,
        properties: FeatureProperties?,
        parent: LayerLike
    ) -> FeatureLike

    func createAnnotationGeometry(
        coordinate: Geometry.Coordinate3D,
        parent: GeometryParent
    ) -> GeometryLike

    func createOverlayGeometry(
        coordinate: Geometry.Coordinate3D,
        boundingBox: Geometry.MapBox,
        shape: GeoShape,
        parent: GeometryParent
    ) -> GeometryLike
}
