//
//  FeaturePropertiesTransformer.swift
//  Georg
//
//  Created by Michael Rockhold on 6/22/24.
//

import Foundation

class FeaturePropertiesTransformer: NSSecureUnarchiveFromDataTransformer {

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override class func transformedValueClass() -> AnyClass {
        return FeatureProperties.self
    }

    override class var allowedTopLevelClasses: [AnyClass] {
        return [NSData.self]
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

    static var transformerName: NSValueTransformerName {
        return NSValueTransformerName(rawValue: "FeaturePropertiesTransformer")
    }

    static func register() {
        ValueTransformer.setValueTransformer(FeaturePropertiesTransformer(),
                                             forName: Self.transformerName)
    }
}
