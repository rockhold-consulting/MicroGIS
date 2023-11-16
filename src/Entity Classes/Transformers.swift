//
//  Transformers.swift
//  Georg
//
//  Created by Michael Rockhold on 11/10/23.
//

import Foundation
import BinaryCodable

public class GeoInfoWrapper: NSObject, NSSecureCoding {
    
    var geoInfo: GeoObject
    
    init(geoInfo: GeoObject) {
        self.geoInfo = geoInfo
    }

    enum CodingKeys: String, CodingKey {
        case geoInfo
    }

    public static var supportsSecureCoding: Bool { return true }
    static var binaryCoder = BinaryEncoder()
    static var binaryDecoder = BinaryDecoder()
    
    public required init?(coder: NSCoder) {
        guard let geoData = coder.decodeData() else {
            print("DECODE ERROR")
            return nil
        }
        guard let gi = try? Self.binaryDecoder.decode(GeoObject.self, from: geoData) else {
            return nil
        }
        self.geoInfo = gi
    }
    
    public func encode(with coder: NSCoder) {
        guard let geoData = try? Self.binaryCoder.encode(geoInfo) else {
            print("ENCODE ERROR")
            return
        }
        coder.encode(geoData)
    }
}

class GeoInfoWrapperTransformer: NSSecureUnarchiveFromDataTransformer {

    override class func allowsReverseTransformation() -> Bool { return true }
    override class func transformedValueClass() -> AnyClass { return GeoInfoWrapper.self }
    override class var allowedTopLevelClasses: [AnyClass] { return [GeoInfoWrapper.self] }
    
    public override func transformedValue(_ value: Any?) -> Any? {
        guard let wrappedGeoInfo = value as? GeoInfoWrapper else {
            fatalError("Wrong data type: value must be a Data object; received \(type(of: value))")
        }
        return super.transformedValue(wrappedGeoInfo)
    }
    
    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let wrappedGeoInfo = value as? GeoInfoWrapper else {
            fatalError("Wrong data type: value must be a GeoObject object; received \(type(of: value))")
        }
        return super.reverseTransformedValue(wrappedGeoInfo)
    }
    
    /// Registers the transformer.
    static let name = NSValueTransformerName(rawValue: String(describing: GeoInfoWrapperTransformer.self))
    public static func register() { ValueTransformer.setValueTransformer(GeoInfoWrapperTransformer(), forName: name) }
}
