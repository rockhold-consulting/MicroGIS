//
//  Feature-Extension.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 3/21/24.
//

import Foundation
import CoreData
import CoreLocation

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

    convenience init(context: NSManagedObjectContext,
                     featureID: String?) {

        self.init(context: context)
        self.featureID = featureID
    }

    func propertyKeys() -> Set<String> {
        return Set<String>(self.properties?.allObjects.map({($0 as! FeatureProperty).key!}) ?? [String]())
    }
}

extension Feature {
    struct GeoInfo {
        let iconSymbolName: String
        let coordString: String

        init(iconSymbolName: String, coordString: String) {
            self.iconSymbolName = iconSymbolName
            self.coordString = coordString
        }
        init(feature: Feature) {
            let cf = CoordinateFormatter(style: .Decimal)
            let icon = "dot.squareshape.split.2x2"

            if let geometries = feature.geometries?.allObjects {
                switch geometries.count {
                case 0:
                    self.init(iconSymbolName: icon,
                                   coordString: "<none>")
                case 1:
                    let g = geometries[0] as! Geometry
                    self.init(iconSymbolName: g.iconSymbolName,
                                   coordString: cf.string(from: g.center))

                default:
                    self.init(iconSymbolName: icon,
                                   coordString: "<many>")
                }
            } else {
                self.init(iconSymbolName: icon,
                               coordString: "<none>")
            }
        }
    }
}
