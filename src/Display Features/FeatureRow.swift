//
//  FeatureRow.swift
//  Georg
//
//  Created by Michael Rockhold on 5/17/24.
//

import SwiftUI
import CoreLocation

struct FeatureRow: View {
    let feature: Feature

    func vm(_ feature: Feature) -> (KitImage, String, String) {
        let cf = CoordinateFormatter(style: .Decimal)
        let icon =  KitImage(systemSymbolName: "dot.squareshape.split.2x2", accessibilityDescription: "feature icon")!

        if let geometries = feature.geometries?.allObjects {
            switch geometries.count {
            case 0:
                return (icon, feature.objectID.shortName, "<error>")
            case 1:
                let g = geometries[0] as! Geometry
                let c = g.coordinate
                return (g.icon, feature.objectID.shortName, cf.string(from: CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude)))
            default:
                return (icon, feature.objectID.shortName, "<many>")
            }
        } else {
            return (icon, feature.objectID.shortName, "<error>")
        }
    }

    var body: some View {
        let (icon, shortName, coordStr) = vm(feature)
        HStack {
            Image(nsImage: icon)
            Text(shortName)
            Text(coordStr)
        }
    }
}

#Preview {
    FeatureRow(feature: Feature())
}
