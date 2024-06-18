//
//  Sidebar.swift
//  Georg
//
//  Created by Michael Rockhold on 5/22/24.
//

import SwiftUI
import CoreLocation

struct Sidebar: View {
    let features: FetchedResults<Feature>
    @Binding var selection: Set<NSManagedObjectID>

    let styleManagers = [
        FakeStyleManager(name: "Simple"),
        FakeStyleManager(name: "Elaborate"),
        FakeStyleManager(name: "Mysterious"),
        FakeStyleManager(name: "Black on Black")
    ]

    var body: some View {
        List(selection: $selection) {
            // TODO: implement this
            Section("Style Rules") {
                ForEach(styleManagers, id: \.name) { styleMgr in
                    NavigationLink(value: styleMgr) {
                        Label(styleMgr.name, systemImage: "building.2")
                    }
                    .listItemTint(.secondary)
                }
            }

            Divider()

            ForEach(features, id: \.self.objectID) { feature in
                FeatureRow(feature: feature)
            }
        }
        .navigationTitle("Features")
//        .navigationDestination(for: FakeStyleManager.self) { styleMgr in
//            Text("StyleManager")
//        }
#if os(macOS)
        .navigationSplitViewColumnWidth(280)
#endif
    }
}

//#Preview {
//    Sidebar()
//}
