//
//  FeatureRow.swift
//  Georg
//
//  Created by Michael Rockhold on 5/17/24.
//

import SwiftUI

struct FeatureRow: View {
    let feature: Feature

    var body: some View {
        Text("F \(feature.title ?? "--")")
    }
}

#Preview {
    FeatureRow(feature: Feature())
}
