//
//  FeatureDetails.swift
//  Georg
//
//  Created by Michael Rockhold on 5/17/24.
//

import SwiftUI

struct FeatureDetails: View {
    struct GeometryViewModel: Identifiable, Hashable {
        let id = UUID()
        let icon: KitImage
        let shapeName: String
        let latitude: String
        let longitude: String
    }
    struct PropertyViewModel: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let value: String
    }

    @State var feature: Feature
    let geometryVMs: [GeometryViewModel]
    let propertyVMs: [PropertyViewModel]

    init(feature f: Feature) {
        self.feature = f
        self.geometryVMs = ((f.kidArray as? [Geometry]) ?? []).map { (g: Geometry) in
            GeometryViewModel(
                icon: g.icon,
                shapeName: g.wrapped?.shape.kindString ?? "??",
                latitude: String(g.wrapped?.baseInfo.coordinate.latitude ?? 0.0),
                longitude: String(g.wrapped?.baseInfo.coordinate.longitude ?? 0.0)
            )
        }
        self.propertyVMs = (f.properties?.data.keys)?.map { k in
           PropertyViewModel(name: k, value: f.properties?.data[k] as? String ?? "??")
        } ?? []
    }

    var body: some View {
        VStack {

            Text("Feature \(feature.objectID) \(feature.title ?? "--")")
//            Table(of: GeometryViewModel.self) {
//                TableColumn("Icon") { g in
//                    Image(nsImage: g.icon)
//                }
//                TableColumn("Shape", value: \.shapeName)
//                TableColumn("Latitude", value: \.latitude)
//                TableColumn("Longitude", value: \.longitude)
//            } rows: {
//                ForEach(geometryVMs) { g in
//                    TableRow(g)
//                }
//            }
            Grid {
                ForEach(geometryVMs, id: \.self) { g in
                    GridRow {
                        Image(nsImage: g.icon)
                        Text(g.shapeName)
                        Text(g.latitude)
                        Text(g.longitude)
                    }
                }
            }
            Grid {
                ForEach(propertyVMs) { (pvm: PropertyViewModel) in
                    GridRow {
                        Text(pvm.name)
                        Text(pvm.value)
                    }
                }
            }
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.gray, lineWidth: 2)
        )
    }
}

//#Preview {
//    FeatureDetails()
//}
