//
//  Transformers.swift
//  Georg
//
//  Created by Michael Rockhold on 11/10/23.
//

import Foundation

class GeoObjectTransformer: NSSecureUnarchiveFromDataTransformer {

    override class func allowsReverseTransformation() -> Bool { return true }
    override class func transformedValueClass() -> AnyClass { return GeoObject.self }
    override class var allowedTopLevelClasses: [AnyClass] { return [GeoObject.self] }
    
    public override func transformedValue(_ value: Any?) -> Any? {
        guard let geoObjectData = value as? Data else {
            fatalError("Wrong data type: value must be a Data object; received \(type(of: value))")
        }
        return super.transformedValue(geoObjectData)
    }
    
    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let geoObject = value as? GeoObject else {
            fatalError("Wrong data type: value must be a GeoObject object; received \(type(of: value))")
        }
        return super.reverseTransformedValue(geoObject)
    }
    
    /// Registers the transformer.
    static let name = NSValueTransformerName(rawValue: String(describing: GeoObjectTransformer.self))
    public static func register() {
        let transformer = GeoObjectTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}
