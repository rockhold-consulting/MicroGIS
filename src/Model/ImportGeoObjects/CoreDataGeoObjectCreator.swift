//
//  CoreDataGeoObjectCreator.swift
//  Georg
//
//  Created by Michael Rockhold on 3/25/24.
//

import Foundation
import CoreData
import BinaryCodable

extension Layer: LayerLike {}
extension Feature: FeatureLike {}
extension Geometry: GeometryLike {}

class CoreDataGeoObjectCreator: GeoObjectCreator {
    

    private let importContext: NSManagedObjectContext
    private let encoder = BinaryEncoder()

    init(importContext: NSManagedObjectContext) {
        self.importContext = importContext
    }

    func createLayer(name: String, importDate: Date) -> LayerLike {
        return Layer(ctx: importContext, name: name, importDate: importDate)
    }

    func createLayer(fileURL: URL) -> LayerLike {
        let name = fileURL.lastPathComponent
        return self.createLayer(name: name.isEmpty ? "Imported Layer" : name, importDate: .now)
    }

    func createFeature(featureID: String?, properties: FeatureProperties?, parent: LayerLike) -> FeatureLike {
        return Feature(
            context: self.importContext,
            featureID: featureID,
            properties: properties,
            parent: parent as? Layer)
    }

    func createAnnotationGeometry(coordinate: Geometry.Coordinate3D, parent: GeometryParent) -> GeometryLike {
        switch parent {
        case let layerParent as Layer:
            return Geometry(
                ctx: importContext,
                coordinate: coordinate,
                boundingBox: nil,
                shape: GeoPoint(coordinate: coordinate),
                layerParent: layerParent)

        case let featureParent as Feature:
            return Geometry(
                ctx: importContext,
                coordinate: coordinate,
                boundingBox: nil,
                shape: GeoPoint(coordinate: coordinate),
                featureParent: featureParent)

        default:
            fatalError()
        }
    }

    func createOverlayGeometry(
        coordinate: Geometry.Coordinate3D,
        boundingBox: Geometry.MapBox,
        shape: GeoShape,
        parent: GeometryParent) -> GeometryLike {
            switch parent {
            case let layerParent as Layer:
                return Geometry(
                    ctx: importContext,
                    coordinate: coordinate,
                    boundingBox: boundingBox,
                    shape: shape,
                    layerParent: layerParent)
            case let featureParent as Feature:
                return Geometry(
                    ctx: importContext,
                    coordinate: coordinate,
                    boundingBox: boundingBox,
                    shape: shape,
                    featureParent: featureParent)
            default:
                fatalError()
            }
        }
}

