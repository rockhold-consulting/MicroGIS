//
//  GeometriesTable.swift
//  Georg
//
//  Created by Michael Rockhold on 6/5/24.
//

import SwiftUI
import CoreLocation

extension Geometry {
    public func matches(searchText: String) -> Bool {
        return false
    }
}

extension Feature {
    public func matches(searchText: String) -> Bool {
        // TODO: search feature properties too
        if self.objectID.shortName.localizedCaseInsensitiveContains(searchText) {
            return true
        }
        return false
    }
}

struct GeometryViewModel: Identifiable {
    let id: String
    let image: KitImage
    let featureID: String
    let coordString: String

    static let coordFormatter = CoordinateFormatter(style: .Decimal)

    init(geometry: Geometry) {
        let c = geometry.coordinate
        let coord = CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude)

        self.id = geometry.objectID.shortName
        self.featureID = geometry.parentID.shortName
        self.image = geometry.icon
        self.coordString = Self.coordFormatter.string(from: coord)
    }
}


struct GeometriesTable: View {

    let managedObjectContext: NSManagedObjectContext
    let features: [Feature]

    @State private var sortOrder = [KeyPathComparator(\GeometryViewModel.id, order: .forward)]
    @Binding var searchText: String

    var geometries: [GeometryViewModel] {
        return self.features.flatMap { feature in
            return feature.geometries?.allObjects as! [Geometry]
        }
        .filter { geometry in
            searchText == "" || (geometry.matches(searchText: searchText) || geometry.parent!.matches(searchText: searchText))
        }
        .map { geometry in
            GeometryViewModel(geometry: geometry)
        }
        .sorted(using: sortOrder)
    }

    var body: some View {
        Table(sortOrder: $sortOrder) {

            TableColumn("Kind") { (gvm: GeometryViewModel) in
                Image(nsImage: gvm.image)
            }

            TableColumn("ID", value: \.id) { gvm in
                Text(gvm.id)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
            }

            TableColumn("Center", value: \.coordString) { gvm in
                Text(gvm.coordString)
                    .monospacedDigit()
                    #if os(macOS)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .foregroundStyle(.secondary)
                    #endif
            }

            TableColumn("Feature", value: \.featureID) { gvm in
                Text(gvm.featureID)
                    #if os(macOS)
                    .foregroundStyle(.secondary)
                    #endif
            }

            TableColumn("Details") { gvm in
                Menu {
                    NavigationLink(value: gvm.id) {
                        Label("View Details", systemImage: "list.bullet.below.rectangle")
                    }
                } label: {
                    Label("Details", systemImage: "ellipsis.circle")
                        .labelStyle(.iconOnly)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .foregroundColor(.secondary)
            }
            .width(60)
        } rows: {
            Section {
                ForEach(geometries) { gvm in
                    TableRow(gvm)
                }
            }
        }
    }
}
//#Preview {
//    GeometriesTable()
//}
