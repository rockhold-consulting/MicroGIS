//
//  Feature-Extension.swift
//  GeorgB
//
//  Created by Michael Rockhold on 3/21/24.
//

import Foundation
import CoreData
import CoreLocation

protocol SimpleJSONObject {

}

extension String: SimpleJSONObject {}
extension NSNumber: SimpleJSONObject {}
extension NSNull: SimpleJSONObject {}

@objc
public class FeatureProperties: NSObject, NSSecureCoding {

    enum PropertiesError: Error {
        case Malformed
    }

    private var data: [String:Any]?

    var names: Set<String> {
        guard let dict = data else {
            return Set<String>()
        }
        return Set<String>(dict.keys)
    }

    init?(data: Data?) throws {

        guard let d = data, let obj = try? JSONSerialization.jsonObject(with: d) else { return nil
        }

        if let dict = obj as? [String:Any] {
            self.data = dict
        } else {
            throw PropertiesError.Malformed
        }
    }

    subscript(index: String) -> String {
        get {
            guard let d = self.data else { return "" }
            if let value = d[index] {
                if value is String {
                    return value as! String
                } else {
                    return "\(value)"
                }
            } else {
                return ""
            }
        }
        set(newValue) {
            if self.data == nil {
                self.data = [String:Any]()
            }
            data![index] = newValue
        }
    }

    func clean() -> [String:String]? {
        func format(_ v: Any) -> String {
            switch v {
            case let s as String:
                return s
            case let i as Int:
                return String(i)
            case let d as Double:
                return String(d)
            case _ as NSNull:
                return "null"
            default:
                return "-??-"
            }
        }

        guard let d = self.data else { return nil }
        var props = [String:String]()
        for (k,v) in d {
            props[k] = format(v)
        }
        return props
    }
    public static var supportsSecureCoding: Bool = true

    required public init?(coder aDecoder: NSCoder) {

        guard let jsonData = aDecoder.decodeData() else {
            return nil
        }

        if let fi = try? JSONSerialization.jsonObject(with: jsonData) as? [String:Any] {
            self.data = fi
        } else {
            return nil
        }
    }

    public func encode(with aCoder: NSCoder) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: self.data) {
            aCoder.encode(jsonData)
        } else {
            fatalError()
        }
    }

}

extension Feature {

    var title: String? {
        get {
            featureID ?? ""
        }
        set {
            featureID = newValue
        }
    }

    var iconSymbolName: String {
        let defaultIcon = "dot.squareshape.split.2x2"
        if (geometries?.count ?? 0) == 1 {
            return (geometries?.first as? Geometry)?.iconSymbolName ?? defaultIcon
        } else {
            return defaultIcon
        }
    }

    convenience init(
        context: NSManagedObjectContext,
        featureID: String?,
        properties: FeatureProperties?,
        parent: Layer
    ) {
        self.init(context: context)
        self.featureID = featureID
        self.properties = properties
        self.parent = parent
        parent.addToFeatures(self)
    }

    func cleanProperties() -> [String:String] {
        guard let c = self.properties?.clean() else {
            return [String:String]()
        }
        return c
    }
}

extension Feature {
    struct GeoInfo {
        let iconSymbolName: String
        let kindName: String
        let coordString: String
    }
    func geoInfo() -> GeoInfo {
            let cf = CoordinateFormatter(style: .Decimal)
            let icon = "dot.squareshape.split.2x2"

            if let geometries = self.geometries?.allObjects {
                switch geometries.count {
                case 0:
                    return GeoInfo(iconSymbolName: icon,
                                   kindName: self.objectID.shortName,
                                   coordString: "<error>")
                case 1:
                    let g = geometries[0] as! Geometry
                    let c = g.coordinate
                    return GeoInfo(iconSymbolName: g.iconSymbolName,
                                   kindName: self.objectID.shortName,
                                   coordString: cf.string(from: CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude)))

                default:
                    return GeoInfo(iconSymbolName: icon,
                                   kindName: self.objectID.shortName,
                                   coordString: "<many>")
                }
            } else {
                return GeoInfo(iconSymbolName: icon,
                               kindName: self.objectID.shortName,
                               coordString: "<error>")
            }
    }
}

class FeaturePropertiesTransformer: NSSecureUnarchiveFromDataTransformer {

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override class func transformedValueClass() -> AnyClass {
        return FeatureProperties.self
    }

    override class var allowedTopLevelClasses: [AnyClass] {
        return [FeatureProperties.self, NSData.self]
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            fatalError("Wrong data type: value must be a Data object; received \(type(of: value))")
        }
        return super.transformedValue(data)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let v = value as? FeatureProperties else {
            fatalError("Wrong data type: value must be a FeatureProperties object; received \(type(of: value))")
        }
        return super.reverseTransformedValue(v)
    }

    static let featurePropertiesTransformerName = NSValueTransformerName(rawValue: "FeaturePropertiesTransformer")

    static func register() {
        ValueTransformer.setValueTransformer(FeaturePropertiesTransformer(),
                                             forName: featurePropertiesTransformerName)
    }
}
