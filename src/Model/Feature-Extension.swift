//
//  Feature-Extension.swift
//  GeorgB
//
//  Created by Michael Rockhold on 3/21/24.
//

import Foundation
import CoreData
import CoreLocation

@objc
public class FeatureProperties: NSObject, NSSecureCoding {

    var data: [String:Any]

    init?(data: Data?) {

        guard let d = data else {
            self.data = [String:Any]()
            return
        }

        guard let _ = try? JSONSerialization.jsonObject(with: d) else {
            return nil
        }

        if let fi = try? JSONSerialization.jsonObject(with: d) as? [String:Any] {
            self.data = fi
        } else {
            self.data = [String:Any]()
        }
    }

    subscript(index: String) -> String {
        get {
            if let value = data[index] {
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
            data[index] = newValue
        }
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
        func clean(_ v: Any) -> String {
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

        var props = [String:String]()
        if let p = self.properties {
            for (k,v) in p.data {
                props[k] = clean(v)
            }
        }
        return props
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
