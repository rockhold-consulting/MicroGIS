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

public extension Feature {
    convenience init(
        context: NSManagedObjectContext,
        featureID: String,
        properties: FeatureProperties?
    ) {
        self.init(context: context)
        self.featureID = featureID
        self.properties = properties
    }

    func add(child: GeometryLike) {
        self.addToChildren(child as! Geometry)
        (child as! Geometry).parent = self
    }
}

extension Feature: FeatureLike {
    public func set(parent: GeoObjectParent) {
        if let p = parent as? Layer {
            self.parent = p
        }
    }

    public func add(child: GeoObjectChild) {
        if let geoChild = child as? Geometry {
            self.addToChildren(geoChild)
        }
    }
}

@objc(FeaturePropertiesTransformer)
public class FeaturePropertiesTransformer: NSSecureUnarchiveFromDataTransformer {
    override public static var allowedTopLevelClasses: [AnyClass] { [FeatureProperties.self] }

    static func register() {
        ValueTransformer.setValueTransformer(FeaturePropertiesTransformer(),
                                             forName: NSValueTransformerName(String(describing: FeaturePropertiesTransformer.self)))
    }

}
