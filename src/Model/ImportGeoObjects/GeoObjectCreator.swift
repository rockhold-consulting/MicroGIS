//
//  GeoObjectCreator.swift
//  Georg
//
//  Created by Michael Rockhold on 3/22/24.
//

import Foundation

public protocol GeoObjectChild {
    func set(parent: GeoObjectParent)
}

public protocol GeoObjectParent {
    func add(child: GeoObjectChild)
}


public protocol LayerLike: GeoObjectParent { }

public protocol FeatureLike: GeoObjectParent, GeoObjectChild { }

public protocol GeometryLike: GeoObjectChild { }

public protocol GeoObjectCreator {

    func createLayer(name: String, importDate: Date) -> LayerLike

    func createFeature(
        parent: GeoObjectParent,
        featureID: String,
        properties: FeatureProperties?
    ) -> FeatureLike

    func createAnnotationGeometry(
        coordinate: Geometry.Coordinate3D,
        title: String?,
        subtitle: String?,
        parent: GeoObjectParent
    )

    func createOverlayGeometry(
        coordinate: Geometry.Coordinate3D,
        boundingBox: Geometry.MapBox,
        shape: GeoShape,
        parent: GeoObjectParent
    )
}
