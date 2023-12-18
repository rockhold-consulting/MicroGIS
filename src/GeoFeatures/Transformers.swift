//
//  Transformers.swift
//  Georg
//
//  Created by Michael Rockhold on 11/10/23.
//

import Foundation

class GeometryTransformer: NSSecureUnarchiveFromDataTransformer {

    override class func allowsReverseTransformation() -> Bool { return true }
    override class func transformedValueClass() -> AnyClass { return Geometry.self }
    override class var allowedTopLevelClasses: [AnyClass] { return [Geometry.self] }
    
    public override func transformedValue(_ value: Any?) -> Any? {
        guard let geoObjectData = value as? Data else {
            fatalError("Wrong data type: value must be a Data object; received \(type(of: value))")
        }
        return super.transformedValue(geoObjectData)
    }
    
    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let geometry = value as? Geometry else {
            fatalError("Wrong data type: value must be a Geometry object; received \(type(of: value))")
        }
        return super.reverseTransformedValue(geometry)
    }
    
    /// Registers the transformer.
    static let name = NSValueTransformerName(rawValue: String(describing: GeometryTransformer.self))
    public static func register() {
        let transformer = GeometryTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}
