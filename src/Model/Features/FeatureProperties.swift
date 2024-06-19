//
//  FeatureProperties.swift
//  Georg
//
//  Created by Michael Rockhold on 6/22/24.
//

import Foundation

@objc
public class FeatureProperties: NSObject, NSSecureCoding {

    public private(set) var data: [String:Any]

    init?(data: Data?) throws {
        guard let d = data, let obj = try? JSONSerialization.jsonObject(with: d), let dict = obj as? [String:Any] else {
            return nil
        }
        self.data = dict
    }

    public static var supportsSecureCoding: Bool = true

    enum CodingKeys: String, CodingKey {
        case propertiesData
    }

    required public init?(coder aDecoder: NSCoder) {
        guard let propertiesData = aDecoder.decodeObject(of: NSData.self, forKey: CodingKeys.propertiesData.rawValue) else {
            return nil
        }

        if let fi = try? JSONSerialization.jsonObject(with: propertiesData as Data) as? [String:Any] {
            self.data = fi
        } else {
            return nil
        }
    }

    public func encode(with aCoder: NSCoder) {
        if let propertiesData = try? JSONSerialization.data(withJSONObject: self.data as Any) {
            aCoder.encode(propertiesData, forKey: CodingKeys.propertiesData.rawValue)
        } else {
            fatalError()
        }
    }

}
