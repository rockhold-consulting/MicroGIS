//
//  FeatureDetails.swift
//  Georg
//
//  Created by Michael Rockhold on 5/17/24.
//

import SwiftUI

extension NSManagedObjectID {
    var shortName: String {
        let uri = self.uriRepresentation().lastPathComponent
        return uri.isEmpty ? "---" : uri
    }
}

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

        init(name: String, value: Any) {
            self.name = name
            switch value {
            case let s as String:
                self.value = s
            case let i as Int:
                self.value = String(i)
            case let d as Double:
                self.value = String(d)
            case let _ as NSNull:
                self.value = "null"
            default:
                self.value = "-??-"
            }
        }
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
            PropertyViewModel(name: k, value: f.properties?.data[k] as Any)
        } ?? []
    }

    var body: some View {
        VStack {
            Text("Feature \(feature.objectID.shortName)")
                .multilineTextAlignment(.leading)
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
            .multilineTextAlignment(.leading)
            Grid {
                ForEach(propertyVMs) { (pvm: PropertyViewModel) in
                    GridRow {
                        Text(pvm.name)
                        Text(pvm.value)
                    }
                }
            }
            .multilineTextAlignment(.trailing)
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
