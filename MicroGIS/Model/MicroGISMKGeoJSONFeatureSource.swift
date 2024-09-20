//
//  ImportMKGeoJSON.swift
//  MicroGIS
//
//  Copyright 2024, Michael Rockhold (dba Rockhold Software)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  The license is provided with this work, or you may obtain a copy
//  of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//  Created by Michael Rockhold on 3/22/24.
//

import Foundation
import CoreLocation
import MapKit
import MapKit.MKGeoJSONSerialization
import OSLog
import CoreData

extension MKPolyline: MultiCoordinate {
    public var center: CLLocationCoordinate2D {
        self.coordinate
    }
    
    public var coordinateCount: Int {
        self.pointCount
    }
}

extension MKPolygon: MultiCoordinate {
    public var center: CLLocationCoordinate2D {
        self.coordinate
    }
    
    public var coordinateCount: Int {
        self.pointCount
    }
}

extension MGPolyline {
    convenience init(with mkPolyline: MKPolyline, 
                     context: NSManagedObjectContext) {
        self.init(context: context,
                  multipointThing:  mkPolyline)
    }
}

extension MGPolygon {
    convenience init(with mkPolygon: MKPolygon, 
                     context: NSManagedObjectContext) {
        let inners: [MGPolygon]
        if let innerPolys = mkPolygon.interiorPolygons {
            inners = innerPolys.map { poly in
                MGPolygon(with: poly, context: context)
            }
        } else {
            inners = [MGPolygon]()
        }

        self.init(context: context,
                  multipointThing:  mkPolygon,
                  innerPolygons: inners)
    }
}

extension MGMultiPolyline {
    convenience init(with mkMultiPolyline: MKMultiPolyline, context: NSManagedObjectContext) {
        self.init(context: context,
                  center: mkMultiPolyline.coordinate,
                  polylines: mkMultiPolyline.polylines.map { MGPolyline(with: $0, context: context)})
    }
}

extension MGMultiPolygon {
    convenience init(with mkMultiPolygon: MKMultiPolygon, context: NSManagedObjectContext) {
        self.init(context: context,
                  center: mkMultiPolygon.coordinate,
                  polygons: mkMultiPolygon.polygons.map { MGPolygon(with: $0, context: context) })
    }
}

extension MGCircle {
    convenience init(with mkCircle: MKCircle, context: NSManagedObjectContext) {
        self.init(context: context,
                  center: mkCircle.coordinate,
                  radius: mkCircle.radius)
    }
}

extension MKGeoJSONFeature {

    func propertiesDictionary() -> [String:Any]? {
        guard let propData = self.properties,
              let propertiesDict = try?
                JSONSerialization.jsonObject(with: propData) as? [String:Any] else {

            return nil
        }
        return propertiesDict
    }
}

public class MicroGISMKGeoJSONFeatureSource {

    let logger: Logger
    private let importContext: NSManagedObjectContext

    init(importContext: NSManagedObjectContext) {
        let bundleID = Bundle(for: MicroGISMKGeoJSONFeatureSource.self).bundleIdentifier!
        logger = Logger(subsystem: bundleID, category: "MicroGISMKGeoJSONFeatureSource")
        self.importContext = importContext
    }

    public func importFeatureCollection(from fileURL: URL) {
        func makeProperty(key k: String, value v: Any) -> FeatureProperty {
            switch v {
            case _ as NSNull:
                return NullFeatureProperty(context: importContext, key: k)

            case let b as Bool:
                return BoolFeatureProperty(context: importContext, key: k, boolValue: b)

            case let i as Int:
                return IntFeatureProperty(context: importContext, key: k, integerValue: i)

            case let d as Double:
                return DoubleFeatureProperty(context: importContext, key: k, doubleValue: d)

            case let s as String:
                if let date = ISO8601DateFormatter().date(from: s) {
                    return DateFeatureProperty(context: importContext, key: k, dateValue: date)
                } else {
                    return StringFeatureProperty(context: importContext, key: k, stringValue: s)
                }

            default: // objects, arrays, and anything unexpected. Unlikely, and probably not useful
                return BlobFeatureProperty(context: importContext, key: k, blobValue: v)
            }
        }


        let collection = FeatureCollection(ctx: importContext,
                                           stylesheet: PersistenceController.shared.defaultStylesheet(),
                                           creationDate: .now,
                                           name: fileURL.lastPathComponent)

        do {
            fileURL.startAccessingSecurityScopedResource()
            for topLevelGeoJSONObject in try MKGeoJSONDecoder().decode(try Data(contentsOf: fileURL)) {

                switch topLevelGeoJSONObject {

                case let shape as MKShape:
                    createFeatureWithGeometry(from: shape, featureCollection: collection)

                case let mkFeature as MKGeoJSONFeature:

                    let feature = createFeature(featureID: mkFeature.identifier)
                    if let props = mkFeature.propertiesDictionary() {
                        for (k,v) in props {
                            feature.addToProperties(makeProperty(key: k, value: v))
                        }
                    }
                    for shape in mkFeature.geometry {
                        let g = createGeometry(from: shape)
                        feature.addToGeometries(g)
                    }
                    collection.addToFeatures(feature)
                    fileURL.stopAccessingSecurityScopedResource()

                default:
                    break
                }
            }
        }
        catch {
            fileURL.stopAccessingSecurityScopedResource()
            self.logger.debug("error decoding GeoJSON file")
        }

    }
}

extension MicroGISMKGeoJSONFeatureSource {

    func createGeometry(from shape: MKShape) -> Geometry {

        switch shape {
        case let pa as MKPointAnnotation:
            return self.makePoint(center: pa.coordinate)

        case let overlay as MKCircle:
            return self.make(circle: overlay)
            // overlay.boundingMapRect

        case let overlay as MKPolyline:
            return self.make(polyline: overlay)

        case let overlay as MKGeodesicPolyline:
            return self.make(geodesicPolyline: overlay)

        case let overlay as MKPolygon:
            return self.make(polygon: overlay)

        case let overlay as MKMultiPolyline:
            return self.make(multiPolyline: overlay)

        case let overlay as MKMultiPolygon:
            return self.make(multiPolygon: overlay)

        default:
            fatalError("unsupported kind of geometry")
            break
        }
    }

    func createFeatureWithGeometry(from shape: MKShape,
                                   featureCollection: FeatureCollection) {
        let feature = self.createFeature(featureID: nil)
        let g = createGeometry(from: shape)
        feature.addToGeometries(g)
        featureCollection.addToFeatures(feature)
    }

    func createFeature(featureID: String?) -> Feature {
        return Feature(
            context: self.importContext,
            featureID: featureID)
    }

    func makePoint(center: CLLocationCoordinate2D) -> MGPoint {
        return MGPoint(context: importContext, center: center)
    }

    func make(circle: MKCircle) -> MGCircle {
        return MGCircle(with: circle, context: importContext)
        // overlay.boundingMapRect
    }

    func make(polyline: MKPolyline) -> MGPolyline {
        return MGPolyline(with: polyline, context: importContext)
    }

    func make(geodesicPolyline: MKGeodesicPolyline) -> MGGeodesicPolyline {
        return MGGeodesicPolyline(with: geodesicPolyline, context: importContext)
    }

    func make(polygon: MKPolygon) -> MGPolygon {
        return MGPolygon(with: polygon, context: importContext)
    }

    func make(multiPolyline: MKMultiPolyline) -> MGMultiPolyline {
        return MGMultiPolyline(with: multiPolyline, context: importContext)
    }

    func make(multiPolygon: MKMultiPolygon) -> MGMultiPolygon {
        return MGMultiPolygon(with: multiPolygon, context: importContext)
    }
}
