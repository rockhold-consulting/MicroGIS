//
//  GeoShapeWrapperTransformer.swift
//  Georg
//
//  Created by Michael Rockhold on 6/22/24.
//

import Foundation

@objc
class GeoShapeWrapperTransformer: NSSecureUnarchiveFromDataTransformer {

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override class func transformedValueClass() -> AnyClass {
        return GeoShapeWrapper.self
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
        guard let v = value as? GeoShape else {
            fatalError("Wrong data type: value must be a GeoShape object; received \(type(of: value))")
        }
        return super.reverseTransformedValue(v)
    }

    static var transformerName: NSValueTransformerName {
        return NSValueTransformerName(rawValue: "GeoShapeWrapperTransformer")
    }

    static func register() {
        ValueTransformer.setValueTransformer(GeoShapeWrapperTransformer(),
                                             forName: transformerName)
    }
}
