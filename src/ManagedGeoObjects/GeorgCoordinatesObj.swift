//
//  Transformers.swift
//  Georg
//
//  Created by Michael Rockhold on 10/31/23.
//

import Foundation
import CoreLocation
import MapKit

public class GeorgCoordinatesObj : NSObject, NSSecureCoding {
    
    enum CodingKeys: String, CodingKey {
        case coordinates
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(coordinates, forKey: CodingKeys.coordinates.rawValue)
    }
    
    public required convenience init?(coder: NSCoder) {
        guard let cs = coder.decodeObject(forKey: CodingKeys.coordinates.rawValue) as? [CLLocationCoordinate2D] else {
            return nil
        }
                
        self.init(coordinates: cs)
     }

    public init(coordinates: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()) {
        self.coordinates = coordinates
    }

    public static var supportsSecureCoding: Bool { return true }

    public var coordinates: [CLLocationCoordinate2D] = []
}

class GeorgCoordinatesObjTransformer: NSSecureUnarchiveFromDataTransformer {
    override class func allowsReverseTransformation() -> Bool { return true }
    override class func transformedValueClass() -> AnyClass { return GeorgCoordinatesObj.self }
    override class var allowedTopLevelClasses: [AnyClass] { return [GeorgCoordinatesObj.self] }
    
    public override func transformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            fatalError("Wrong data type: value must be a Data object; received \(type(of: value))")
        }
        return super.transformedValue(data)
    }
    
    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let location = value as? GeorgCoordinatesObj else {
            fatalError("Wrong data type: value must be a GeorgCoordinatesObj object; received \(type(of: value))")
        }
        return super.reverseTransformedValue(location)
    }
    
    /// Registers the transformer.
    static let name = NSValueTransformerName(rawValue: String(describing: GeorgCoordinatesObjTransformer.self))
    public static func register() { ValueTransformer.setValueTransformer(GeorgCoordinatesObjTransformer(), forName: name) }
}

//class CGOAnnotationTransformer: NSSecureUnarchiveFromDataTransformer {
//    override class func allowsReverseTransformation() -> Bool { return true }
//    override class func transformedValueClass() -> AnyClass { return CGOAnnotation.self }
//    override class var allowedTopLevelClasses: [AnyClass] { return [CGOAnnotation.self] }
//
//    override func transformedValue(_ value: Any?) -> Any? {
//        guard let data = value as? Data else {
//            fatalError("Wrong data type: value must be a Data object; received \(type(of: value))")
//        }
//        return super.transformedValue(data)
//    }
//
//    override func reverseTransformedValue(_ value: Any?) -> Any? {
//        guard let annotation = value as? CGOAnnotation else {
//            fatalError("Wrong data type: value must be a CGOAnnotation object; received \(type(of: value))")
//        }
//        return super.reverseTransformedValue(annotation)
//    }
//
//    static let name = NSValueTransformerName(rawValue: String(describing: CGOAnnotationTransformer.self))
//    public static func register() { ValueTransformer.setValueTransformer(CGOAnnotationTransformer(), forName: name) }
//}

//class Transformer<T>: NSSecureUnarchiveFromDataTransformer {
//    
//    override class func allowsReverseTransformation() -> Bool { return true }
//    override class func transformedValueClass() -> AnyClass { return T.self as! AnyClass }
//
//    override func transformedValue(_ value: Any?) -> Any? {
//        guard let data = value as? Data else {
//            fatalError("Wrong data type: value must be a Data object; received \(type(of: value))")
//        }
//        return super.transformedValue(data)
//    }
//    
//    override func reverseTransformedValue(_ value: Any?) -> Any? {
//        guard let t = value as? T else {
//            fatalError("Wrong data type; received \(type(of: value))")
//        }
//        return super.reverseTransformedValue(t)
//    }
//    
//    public static func register(_ name: NSValueTransformerName) { ValueTransformer.setValueTransformer(Transformer<T>(), forName: name) }
//}
//
//
////class CircleTransformer: NSSecureUnarchiveFromDataTransformer {
////    
////    override class func allowsReverseTransformation() -> Bool { return true }
////    override class func transformedValueClass() -> AnyClass { return MKCircle.self }
////    override class var allowedTopLevelClasses: [AnyClass] { return [MKCircle.self] }
////
////    override func transformedValue(_ value: Any?) -> Any? {
////        guard let data = value as? Data else {
////            fatalError("Wrong data type: value must be a Data object; received \(type(of: value))")
////        }
////        return super.transformedValue(data)
////    }
////    
////    override func reverseTransformedValue(_ value: Any?) -> Any? {
////        guard let circle = value as? MKCircle else {
////            fatalError("Wrong data type: value must be a MKCircle object; received \(type(of: value))")
////        }
////        return super.reverseTransformedValue(circle)
////    }
////    
////    static let name = NSValueTransformerName(rawValue: String(describing: CircleTransformer.self))
////    public static func register() { ValueTransformer.setValueTransformer(CircleTransformer(), forName: name) }
////}
//
//public typealias GeorgCircle = MKCircle
//typealias CircleTransformer = Transformer<GeorgCircle>
//
//public typealias GeorgClusterAnnotation = MKClusterAnnotation
//typealias ClusterAnnotationTransformer = Transformer<GeorgClusterAnnotation>
//
//public typealias GeorgGeodesicPolyline = MKGeodesicPolyline
//typealias GeodesicPolylineTransformer = Transformer<GeorgGeodesicPolyline>
//
////typealias GeorgMapFeatureAnnotation = MKMapFeatureAnnotation
//
//
//public typealias GeorgMultiPolyline = MKMultiPolyline
//typealias MultiPolylineTransformer = Transformer<GeorgMultiPolyline>
//
//public typealias GeorgPlacemark = MKPlacemark
//typealias PlacemarkTransformer = Transformer<GeorgPlacemark>
//
//public typealias GeorgPointAnnotation = MKPointAnnotation
//typealias PointAnnotationTransformer = Transformer<GeorgPointAnnotation>
//
//class GeorgPolygon: MKPolygon, Codable {
//    init(basePolygon: MKPolygon) {
//        interiorPolygons = basePolygon.interiorPolygons.map { p in
//            GeorgPolygon(basePolygon: p)
//        }
//        super.init()
//    }
//}
//typealias PolygonTransformer = Transformer<GeorgPolygon>
//
//public typealias GeorgPolyline = MKPolyline
//typealias PolylineTransformer = Transformer<GeorgPolyline>
//
//public typealias GeorgTileOverlay = MKTileOverlay
//typealias TileOverlayTransformer = Transformer<GeorgTileOverlay>
//
//class GeorgMultiPolygon: MKMultiPolygon, Codable {
//    public init(basePolygon: MKMultiPolygon) {
//        self.polygons = basePolygon.polygons.map { basePolygon in
//            GeorgPolygon(basePolygon: basePolygon)
//        }
//        super.init()
//    }
//    
//    public required init(from decoder: Decoder) throws {
//        
//    }
//    
//    public func encode(to encoder: Encoder) throws {
//        
//    }
//    
//    public static var supportsSecureCoding: Bool { return true }
//}
//typealias MultiPolygonTransformer = Transformer<GeorgMultiPolygon>
//
//extension NSValueTransformerName {
//    static let circleTransformer = NSValueTransformerName(rawValue: "CircleTransformer")
//    static let clusterAnnotationTransformer = NSValueTransformerName(rawValue: "ClusterAnnotationTransformer")
//    static let geodesicPolylineTransformer = NSValueTransformerName(rawValue: "GeodesicPolylineTransformer")
//    static let multiPolygonTransformer = NSValueTransformerName(rawValue: "MultiPolygonTransformer")
//    static let multiPolylineTransformer = NSValueTransformerName(rawValue: "MultiPolylineTransformer")
//    static let placemarkTransformer = NSValueTransformerName(rawValue: "PlacemarkTransformer")
//    static let pointAnnotationTransformer = NSValueTransformerName(rawValue: "PointAnnotationTransformer")
//    static let polylineTransformer = NSValueTransformerName(rawValue: "PolylineTransformer")
//    static let tileOverlayTransformer = NSValueTransformerName(rawValue: "TileOverlayTransformer")
//}
