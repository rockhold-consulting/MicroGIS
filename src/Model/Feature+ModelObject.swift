//
//  Feature+.swift
//  GeorgB
//
//  Created by Michael Rockhold on 3/21/24.
//

import Foundation
import CoreData

@objc public class FeatureProperties: NSObject, NSSecureCoding {

    var data: [String:Any]

    var featureID: String? {
        // attempt to find an appropriate ID among the keys
        for key in ["ID", "id", "identifier", "IDENTIFIER", "featureID"] {
            if let fID = data[key] {
                return fID is String ? fID as! String : "\(fID)"
            }
        }
        return nil
    }

    init(data: Data?) {

        guard let d = data else {
            self.data = [String:Any]()
            return
        }

        guard let _ = try? JSONSerialization.jsonObject(with: d) else {
            fatalError()
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

    required public init(coder aDecoder: NSCoder) {

        guard let jsonData = aDecoder.decodeData() else {
            fatalError()
        }

        guard let _ = try? JSONSerialization.jsonObject(with: jsonData) else {
            fatalError()
        }

        if let fi = try? JSONSerialization.jsonObject(with: jsonData) as? [String:Any] {
            self.data = fi
        } else {
            self.data = [String:Any]()
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

extension Feature: ModelObject {    

    var title: String? {
        get {
            featureID ?? ""
        }
        set {
            featureID = newValue
        }
    }

    var identifier: NSObject { self.objectID }

    var isLeaf: Bool { (geometries?.count ?? 0) > 1 }

    var kidArray: [ModelObject]? { (geometries?.array as! [ModelObject]) }

    var icon: KitImage {
        let defaultIcon = KitImage(systemSymbolName: "dot.squareshape.split.2x2", accessibilityDescription: "feature icon")!
        if (geometries?.count ?? 0) == 1 {
            return (geometries?.first as? Geometry)?.icon ?? defaultIcon
        } else {
            return defaultIcon
        }
    }

    convenience init(
        context: NSManagedObjectContext,
        featureID: String?,
        properties: FeatureProperties?,
        parent: Layer?
    ) {
        self.init(context: context)
        self.featureID = featureID
        self.properties = properties
        self.parent = parent
        parent?.addToFeatures(self)
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
