//
//  CoordinateFormatter.swift
//  Georg
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
