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

    var body: some View {

        let cf = CoordinateFormatter(style: .Decimal)
        let c = (feature.kidArray?[0] as? Geometry)?.coordinate ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)

        HStack {
            Image(nsImage: feature.icon)
            Text(feature.objectID.shortName)
            Text(cf.string(from: CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude)))
        }
    }
}

#Preview {
    FeatureRow(feature: Feature())
}
