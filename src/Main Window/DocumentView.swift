//
//  DocumentView.swift
//  Georg
//
//  Created by Michael Rockhold on 5/16/24.
//

import SwiftUI

struct DocumentView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var features: FetchedResults<Feature>

    @State private var selection: Feature?

    var body: some View {

        NavigationSplitView {
            List(features, id: \.self, selection: $selection) { feature in
                FeatureRow(feature: feature)
            }
            .navigationTitle("Features")

        } detail: {
            FeatureDetails(feature: selection)
        }
    }
}

#Preview {
    DocumentView()
}
