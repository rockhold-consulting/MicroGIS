//
//  Geometry-Extension.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 3/21/24.
//

import Foundation
import CoreData

public extension Geometry {

    struct BoundingVolume : Codable, Hashable {
        let x: Double
        let y: Double
        let z: Double
        let w: Double
        let h: Double
        let d: Double

        init(x: Double = 0.0, y: Double = 0.0, z: Double = 0.0, w: Double = 0.0, h: Double = 0.0, d: Double = 0.0) {
            self.x = x
            self.y = y
            self.z = z
            self.w = w
            self.h = h
            self.d = d
        }
    }

    convenience init(
        context: NSManagedObjectContext,
        latitude: Double,
        longitude: Double,
        altitude: Double,
        boundsX: Double,
        boundsY: Double,
        boundsZ: Double,
        boundsW: Double,
        boundsH: Double,
        boundsD: Double,
        shape: GeoShape,
        parent: Feature
    ) {
        self.init(context: context)
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.boundsX = boundsX
        self.boundsY = boundsY
        self.boundsZ = boundsZ
        self.boundsW = boundsW
        self.boundsH = boundsH
        self.boundsD = boundsD
        self.shape = GeoShapeWrapper(shape: shape)
        self.feature = parent
    }

    convenience init(context: NSManagedObjectContext,
                     center: Coordinate3D,
                     boundingVolume: BoundingVolume,
                     shape: GeoShape,
                     parent: Feature
    ) {
        self.init(context: context,
                  latitude: center.latitude,
                  longitude: center.longitude,
                  altitude: center.altitude,
                  boundsX: boundingVolume.x,
                  boundsY: boundingVolume.y,
                  boundsZ: boundingVolume.z,
                  boundsW: boundingVolume.w,
                  boundsH: boundingVolume.h,
                  boundsD: boundingVolume.d,
                  shape: shape,
                  parent: parent)
    }

    var center: Coordinate3D {
        return Coordinate3D(latitude: latitude, longitude: longitude, altitude: altitude)
    }

    var boundingVolume: BoundingVolume {
        return BoundingVolume(x: boundsX,
                              y: boundsY,
                              z: boundsZ,
                              w: boundsW,
                              h: boundsH,
                              d: boundsD)
    }
}

public typealias GeometryID = NSManagedObjectID

extension Geometry { // conveniences

    var title: String? { GeometryFormatter().string(from: self) }

    var iconSymbolName: String { shape?.shape.iconSymbolName ?? "mappin.and.ellipse" }

    static let coordFormatter = CoordinateFormatter(style: .Decimal)

    var parentID: NSManagedObjectID? { self.feature?.objectID }

    var shortName: String { self.objectID.shortName }

    var featureShortName: String { self.parentID?.shortName ?? "?" }

    var shapeCode: GeoShape.GeoShapeType { shape?.shape.shapeCode ?? .Invalid }

    var property: [String:Any] { self.feature?.properties?.data ?? [String:Any]() }

    var isPoint: Bool { shape!.shape is GeoPoint }

    var isPolyline: Bool { shape?.shape is GeoPolyline }

    var isMultiPolyline: Bool { shape?.shape is GeoMultiPolyline }

    var isPolylineish: Bool { isPolyline || isMultiPolyline }

    var isGeodesic: Bool { shape?.shape is GeoGeodesicPolyline }
}
