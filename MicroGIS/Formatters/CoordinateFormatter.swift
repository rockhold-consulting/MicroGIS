//
//  CoordinateFormatter.swift
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
//  Created by Michael Rockhold on 5/18/24.
//

import Foundation
import CoreLocation

class CoordinateFormatter: Formatter {
    enum Style {
        case Decimal
        case DMS
    }

    let style: Style

    init(style: Style) {
        self.style = style
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func string(from c: CLLocationCoordinate2D) -> String {

        if style == .Decimal {
            let nf = NumberFormatter()
            nf.numberStyle = .decimal
            nf.maximumFractionDigits = 3

            let latStr = nf.string(from: NSNumber(floatLiteral: c.latitude))!
            let lngStr = nf.string(from: NSNumber(floatLiteral: c.longitude))!

            return "\(latStr), \(lngStr)"

        } else {
            return "TODO"
        }
    }
}
