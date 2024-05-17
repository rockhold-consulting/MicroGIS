//
//  FeatureDetails.swift
//  Georg
//
//  Created by Michael Rockhold on 5/17/24.
//

import SwiftUI

struct FeatureDetails: View {
    var feature: Feature?

    var body: some View {
        Text("Feature details go here \(feature?.title ?? "--")")
            .padding(EdgeInsets(top: 10, leading: 0, bottom: 4, trailing: 0))
            .navigationTitle(feature?.title ?? "--")
        Spacer()
    }
}

#Preview {
    FeatureDetails()
}
