//
//  Sidebar.swift
//  Georg
//
//  Created by Michael Rockhold on 5/22/24.
//

import SwiftUI
import CoreLocation

struct FeatureItemVM: Identifiable {
    let id: String
    let icon: KitImage
    let coordStr: String
}

extension Feature {
    func vm() -> FeatureItemVM {
        let cf = CoordinateFormatter(style: .Decimal)
        var coord = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        var icon =  KitImage(systemSymbolName: "dot.squareshape.split.2x2", accessibilityDescription: "feature icon")!
        if let g = self.kidArray?[0] as? Geometry {
            let c = g.coordinate
            coord = CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude)
            icon = g.icon
        }
        return FeatureItemVM(id: self.objectID.shortName, icon: icon, coordStr: cf.string(from: coord))
    }
}


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
//                ForEach(features) { feature in
//                    let vm = feature.vm()
//                    NavigationLink(value: feature) {
//                        Label {
//                            Text(vm.id)
//                            Text(vm.coordStr)
//                        } icon: {
//                            Image(nsImage: vm.icon)
//                        }
//                    }
//                    .listItemTint(.secondary)
//                }
//            }
        }
        .navigationTitle("Features")
        .navigationDestination(for: FakeStyleManager.self) { styleMgr in
            Text("StyleManager")
        }
//        .navigationDestination(for: Feature.self) { feature in
//            Text("Feature")
//        }
#if os(macOS)
        .navigationSplitViewColumnWidth(280)
#endif
    }
}

//#Preview {
//    Sidebar()
//}
