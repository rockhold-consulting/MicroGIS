//
//  Sidebar.swift
//  Georg
//
//  Created by Michael Rockhold on 5/22/24.
//

import SwiftUI

struct Sidebar: View {
    let features: FetchedResults<Feature>
    @Binding var selection: Set<NSManagedObjectID>

    var body: some View {
        List(selection: $selection) {
            ForEach(features, id: \.self.objectID) { feature in
                FeatureRow(feature: feature)
            }
        }
        .navigationTitle("Features")
        .navigationSplitViewColumnWidth(280)
    }
}

//#Preview {
//    Sidebar()
//}
