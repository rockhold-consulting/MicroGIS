//
//  Feature-Extension.swift
//  MicroGIS
//
//  Copyright 2024, Michael Rockhold (dba Rockhold Software)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  The license is provided with this work, or you may obtain a copy
//  of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
