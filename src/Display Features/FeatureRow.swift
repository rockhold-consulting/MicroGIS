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
        let g = feature.geoInfo()
        HStack {
            Image(systemName: g.iconSymbolName)
            Text(g.kindName)
            Text(g.coordString)
        }
    }
}

#Preview {
    FeatureRow(feature: Feature())
}
