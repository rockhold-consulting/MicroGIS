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

extension Geometry.Coordinate3D {
    init(fromCLLocationCoordinate2D coord2D: CLLocationCoordinate2D) {
        latitude = coord2D.latitude
        longitude = coord2D.longitude
        altitude = 0.0
    }
}

extension Geometry.MapBox {
    init(fromMKMapRect mr: MKMapRect) {
        x = mr.origin.x
        y = mr.origin.y
        z = 0.0
        width = mr.size.width
        height = mr.size.height
        depth = 0.0
    }
}

extension GeoPolyline {
    init(with mkPolyline: MKPolyline) {
        var locationCoordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
                                                           count: mkPolyline.pointCount)
        mkPolyline.getCoordinates(&locationCoordinates, range: NSRange(location: 0, length: mkPolyline.pointCount))
        self.coordinates = locationCoordinates.map { locationCoordinate in
            Geometry.Coordinate3D(fromCLLocationCoordinate2D: locationCoordinate)
        }
    }
}

extension GeoGeodesicPolyline {
    init(with mkGeodesicPolyline: MKGeodesicPolyline) {
        var locationCoordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
                                                           count: mkGeodesicPolyline.pointCount)
        mkGeodesicPolyline.getCoordinates(&locationCoordinates, range: NSRange(location: 0, length: mkGeodesicPolyline.pointCount))
        self.coordinates = locationCoordinates.map { locationCoordinate in
            Geometry.Coordinate3D(fromCLLocationCoordinate2D: locationCoordinate)
        }
    }
}

extension GeoPolygon {
    init(with mkPolygon: MKPolygon) {
        var locationCoordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
                                                           count: mkPolygon.pointCount)
        mkPolygon.getCoordinates(&locationCoordinates, range: NSRange(location: 0, length: mkPolygon.pointCount))
        self.coordinates = locationCoordinates.map { locationCoordinate in
            Geometry.Coordinate3D(fromCLLocationCoordinate2D: locationCoordinate)
        }
        if let innerPolys = mkPolygon.interiorPolygons {

            self.innerPolygons = innerPolys.map { poly in
                GeoPolygon(with: poly)
            }
        } else {
            self.innerPolygons = [GeoPolygon]()
        }
    }
}

extension GeoMultiPolyline {
    init(with mkMultiPolyline: MKMultiPolyline) {
        self.polylines = mkMultiPolyline.polylines.map { mkPolyline in
            GeoPolyline(with: mkPolyline)
        }
    }
}

extension GeoMultiPolygon {
    init(with mkMultiPolygon: MKMultiPolygon) {
        self.polygons = mkMultiPolygon.polygons.map { mkPolygon in
            GeoPolygon(with: mkPolygon)
        }
    }
}

extension GeoCircle {
    init(with mkCircle: MKCircle) {
        self.center = Geometry.Coordinate3D(fromCLLocationCoordinate2D: mkCircle.coordinate)
        self.radius = mkCircle.radius
        self.depth = 0.0
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
                coordinate: Geometry.Coordinate3D(fromCLLocationCoordinate2D: pa.coordinate), parent: parent)

        case let overlay as MKCircle:
            let _ = self.createOverlayGeometry(
                coordinate: Geometry.Coordinate3D(fromCLLocationCoordinate2D: overlay.coordinate),
                boundingBox: Geometry.MapBox(fromMKMapRect: overlay.boundingMapRect),
                shape: GeoCircle(with: overlay), parent: parent)

        case let overlay as MKMultiPolygon:
            let _ = self.createOverlayGeometry(
                coordinate: Geometry.Coordinate3D(fromCLLocationCoordinate2D: overlay.coordinate),
                boundingBox: Geometry.MapBox(fromMKMapRect: overlay.boundingMapRect),
                shape: GeoMultiPolygon(with: overlay), parent: parent)

        case let overlay as MKMultiPolyline:
            let _ = self.createOverlayGeometry(
                coordinate: Geometry.Coordinate3D(fromCLLocationCoordinate2D: overlay.coordinate),
                boundingBox: Geometry.MapBox(fromMKMapRect: overlay.boundingMapRect),
                shape: GeoMultiPolyline(with: overlay), parent: parent)

        case let overlay as MKPolygon:
            let _ = self.createOverlayGeometry(
                coordinate: Geometry.Coordinate3D(fromCLLocationCoordinate2D: overlay.coordinate),
                boundingBox: Geometry.MapBox(fromMKMapRect: overlay.boundingMapRect),
                shape: GeoPolygon(with: overlay), parent: parent)

        case let overlay as MKPolyline:
            let _ = self.createOverlayGeometry(
                coordinate: Geometry.Coordinate3D(fromCLLocationCoordinate2D: overlay.coordinate),
                boundingBox: Geometry.MapBox(fromMKMapRect: overlay.boundingMapRect),
                shape: GeoPolyline(with: overlay), parent: parent)

        case let overlay as MKGeodesicPolyline:
            let _ = self.createOverlayGeometry(
                coordinate: Geometry.Coordinate3D(fromCLLocationCoordinate2D: overlay.coordinate),
                boundingBox: Geometry.MapBox(fromMKMapRect: overlay.boundingMapRect),
                shape: GeoGeodesicPolyline(with: overlay), parent: parent)

        default:
            fatalError("unsupported kind of geometry")
            break
        }
    }

    func createFeatureWithGeometry(from shape: MKShape, parent: LayerLike) {
        let feature = self.createFeature(
            featureID: nil,
            properties: nil,
            parent: parent
        )
        self.createGeometry(from: shape, parent: feature as! Feature)
    }
}

public class GeorgMKGeoJSONFeatureSource {

    let logger = Logger(subsystem: "org.appel-rockhold.Georg", category: "GeorgMKGeoJSONFeatureSource")

    public func importLayer(from fileURL: URL, creator: GeoObjectCreator) {

        let name = fileURL.lastPathComponent
        let layer = creator.createLayer(name: name.isEmpty ? "Imported Layer" : name, importDate: .now)

        do {
            for topLevelGeoJSONObject in try MKGeoJSONDecoder().decode(try Data(contentsOf: fileURL)) {

                switch topLevelGeoJSONObject {

                case let shape as MKShape:
                    creator.createFeatureWithGeometry(from: shape, parent: layer)

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
                        parent: layer
                    )
                    for shape in mkFeature.geometry {
                        creator.createGeometry(from: shape, parent: feature as! Feature)
                    }

                default:
                    break
                }
            }
        }
        catch {
            self.logger.debug("error decoding GeoJSON file")
        }

    }
}
