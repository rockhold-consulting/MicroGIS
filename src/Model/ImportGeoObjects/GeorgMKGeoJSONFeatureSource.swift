//
//  ImportMKGeoJSON.swift
//  GeorgB
//
//  Created by Michael Rockhold on 3/22/24.
//

import Foundation
import CoreLocation
import MapKit
import MapKit.MKGeoJSONSerialization
import OSLog

extension Coordinate3D {
    init(fromCLLocationCoordinate2D coord2D: CLLocationCoordinate2D) {
        self.init(latitude: coord2D.latitude, longitude: coord2D.longitude, altitude: 0.0)
    }
}

extension Geometry.BoundingVolume {
    init(fromMKMapRect mr: MKMapRect) {
        x = mr.origin.x
        y = mr.origin.y
        z = 0.0
        w = mr.size.width
        h = mr.size.height
        d = 0.0
    }
}

extension GeoPolyline {
    convenience init(with mkPolyline: MKPolyline) {
        var locationCoordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
                                                           count: mkPolyline.pointCount)
        mkPolyline.getCoordinates(&locationCoordinates, range: NSRange(location: 0, length: mkPolyline.pointCount))
        
        self.init(coordinates: locationCoordinates.map { locationCoordinate in
            Coordinate3D(fromCLLocationCoordinate2D: locationCoordinate)
        })
    }
}

extension GeoPolygon {
    convenience init(with mkPolygon: MKPolygon) {
        var locationCoordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
                                                           count: mkPolygon.pointCount)
        mkPolygon.getCoordinates(&locationCoordinates, range: NSRange(location: 0, length: mkPolygon.pointCount))
        let coordinates = locationCoordinates.map { locationCoordinate in
            Coordinate3D(fromCLLocationCoordinate2D: locationCoordinate)
        }
        if let innerPolys = mkPolygon.interiorPolygons {
            self.init(coordinates: coordinates, innerPolygons: innerPolys.map { poly in
                GeoPolygon(with: poly)
            })
        } else {
            self.init(coordinates: coordinates)
        }
    }
}

extension GeoMultiPolyline {
    convenience init(with mkMultiPolyline: MKMultiPolyline) {
        self.init(polylines: mkMultiPolyline.polylines.map { mkPolyline in
            GeoPolyline(with: mkPolyline)
        })
    }
}

extension GeoMultiPolygon {
    convenience init(with mkMultiPolygon: MKMultiPolygon) {
        self.init(polygons: mkMultiPolygon.polygons.map { mkPolygon in
            GeoPolygon(with: mkPolygon)
        })
    }
}

extension GeoCircle {
    convenience init(with mkCircle: MKCircle) {
        self.init(center: Coordinate3D(fromCLLocationCoordinate2D: mkCircle.coordinate), radius: mkCircle.radius, depth: 0.0)
    }
}

extension MKGeoJSONFeature {

    var propertiesDictionary: FeatureProperties? {
        guard let propData = self.properties, let fi = try? JSONSerialization.jsonObject(with: propData) as? FeatureProperties else {
            return nil
        }
        return fi
    }
}

extension GeoObjectCreator {

    func createGeometry(from shape: MKShape, parent: Feature) {

        switch shape {
        case let pa as MKPointAnnotation:
            let _ = self.createAnnotationGeometry(
                center: Coordinate3D(fromCLLocationCoordinate2D: pa.coordinate),
                parent: parent)

        case let overlay as MKCircle:
            let _ = self.createOverlayGeometry(
                center: Coordinate3D(fromCLLocationCoordinate2D: overlay.coordinate),
                boundingVolume: Geometry.BoundingVolume(fromMKMapRect: overlay.boundingMapRect),
                shape: GeoCircle(with: overlay), parent: parent)

        case let overlay as MKMultiPolygon:
            let _ = self.createOverlayGeometry(
                center: Coordinate3D(fromCLLocationCoordinate2D: overlay.coordinate),
                boundingVolume: Geometry.BoundingVolume(fromMKMapRect: overlay.boundingMapRect),
                shape: GeoMultiPolygon(with: overlay), parent: parent)

        case let overlay as MKMultiPolyline:
            let _ = self.createOverlayGeometry(
                center: Coordinate3D(fromCLLocationCoordinate2D: overlay.coordinate),
                boundingVolume: Geometry.BoundingVolume(fromMKMapRect: overlay.boundingMapRect),
                shape: GeoMultiPolyline(with: overlay), parent: parent)

        case let overlay as MKPolygon:
            let _ = self.createOverlayGeometry(
                center: Coordinate3D(fromCLLocationCoordinate2D: overlay.coordinate),
                boundingVolume: Geometry.BoundingVolume(fromMKMapRect: overlay.boundingMapRect),
                shape: GeoPolygon(with: overlay), parent: parent)

        case let overlay as MKPolyline:
            let _ = self.createOverlayGeometry(
                center: Coordinate3D(fromCLLocationCoordinate2D: overlay.coordinate),
                boundingVolume: Geometry.BoundingVolume(fromMKMapRect: overlay.boundingMapRect),
                shape: GeoPolyline(with: overlay), parent: parent)

        case let overlay as MKGeodesicPolyline:
            let _ = self.createOverlayGeometry(
                center: Coordinate3D(fromCLLocationCoordinate2D: overlay.coordinate),
                boundingVolume: Geometry.BoundingVolume(fromMKMapRect: overlay.boundingMapRect),
                shape: GeoGeodesicPolyline(with: overlay), parent: parent)

        default:
            fatalError("unsupported kind of geometry")
            break
        }
    }

    func createFeatureWithGeometry(from shape: MKShape, featureCollection: FeatureCollectionLike) {
        let feature = self.createFeature(
            featureID: nil,
            properties: nil,
            parent: featureCollection
        )
        self.createGeometry(from: shape, parent: feature as! Feature)
    }
}

public class GeorgMKGeoJSONFeatureSource {

    let logger = Logger(subsystem: "org.appel-rockhold.Georg", category: "GeorgMKGeoJSONFeatureSource")

    public func importFeatureCollection(from fileURL: URL, into collection: FeatureCollectionLike, creator: GeoObjectCreator) {

        do {
            fileURL.startAccessingSecurityScopedResource()
            for topLevelGeoJSONObject in try MKGeoJSONDecoder().decode(try Data(contentsOf: fileURL)) {

                switch topLevelGeoJSONObject {

                case let shape as MKShape:
                    creator.createFeatureWithGeometry(from: shape, featureCollection: collection)

                case let mkFeature as MKGeoJSONFeature:
                    var featureProperties: FeatureProperties? = nil
                    do {
                        featureProperties = try FeatureProperties(data: mkFeature.properties)
                    } catch {
                        // TODO: log this
                    }

                    let feature = creator.createFeature(
                        featureID: mkFeature.identifier,
                        properties: featureProperties,
                        parent: collection
                    )
                    for shape in mkFeature.geometry {
                        creator.createGeometry(from: shape, parent: feature as! Feature)
                    }
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
