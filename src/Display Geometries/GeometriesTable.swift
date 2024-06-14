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

extension TableColumnContent {

    public func trailing_alignment() -> some TableColumnContent<Self.TableRowValue, Self.TableColumnSortComparator> {

        if #available(macOS 14.0, *) {
            return alignment(.trailing)
        } else {
            // Fallback on earlier versions
            return self
        }
    }

    public func leading_alignment() -> some TableColumnContent<Self.TableRowValue, Self.TableColumnSortComparator> {

        if #unavailable(macOS 14.4, iOS 17.2) {
            // Fallback on earlier versions
            return self
        } else {
            return alignment(.leading)
        }
    }
}

extension TableColumnBuilder {
    /// Creates a single, sortable column result.
    static func buildEither<Column>(first: Column) -> Column where RowValue == Column.TableRowValue, Sort == Column.TableColumnSortComparator, Column : TableColumnContent  {
        return first
    }
    static func buildEither<Column>(second: Column) -> Column where RowValue == Column.TableRowValue, Sort == Column.TableColumnSortComparator, Column : TableColumnContent  {
        return second
    }
}

struct PropertyColumn: Identifiable {
    let id = UUID()
    let str: String
}

struct GeometriesTable: View {

    let managedObjectContext: NSManagedObjectContext
    let features: [Feature]
    let columns: [PropertyColumn]
    let geometries: [Geometry]

    @State private var sortOrder = [KeyPathComparator(\Geometry.id, order: .forward)]
    var searchText: String = ""

    init(managedObjectContext: NSManagedObjectContext, features: [Feature], searchText: String) {

        self.searchText = searchText
        self.managedObjectContext = managedObjectContext
        self.features = features

        self.columns = features.reduce(Set<String>()) { set, f in
            if let k = f.properties?.data.keys {
                return set.union(k)
            } else {
                return set
            }
        }
        .sorted(using: .localizedStandard)
        .map { PropertyColumn(str: $0) }

        var temp_geometries = features.flatMap { feature in
            return feature.geometries?.allObjects as! [Geometry]
        }
        .filter { geometry in
            searchText == "" || (geometry.matches(searchText: searchText) || geometry.parent!.matches(searchText: searchText))
        }

        self.geometries = temp_geometries
    }

    var body: some View {
        Table(sortOrder: $sortOrder) {

            TableColumn(" ", value: \.shapeCode.rawValue) { g in
                Menu {
                    NavigationLink(value: g.id) {
                        Label("View Details", systemImage: "list.bullet.below.rectangle")
                    }
                } label: {
                        Image(nsImage: g.icon)
                            .frame(width: 20, alignment: .center)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .labelStyle(.titleAndIcon)
                .contentShape(Rectangle())
            }
            .width(20)

            TableColumn("ID", value: \.id) { g in
                Text(g.shortName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
            }
            .width(60)
            .leading_alignment()

            TableColumn("Center", value: \.coordString) { g in
                Text(g.coordString)
                    .monospacedDigit()
#if os(macOS)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .foregroundStyle(.secondary)
#endif
            }
            .width(130)
            .trailing_alignment()

            TableColumn("Feature ID", value: \.featureShortName) { g in
                Text(g.featureShortName)
#if os(macOS)
                    .foregroundStyle(.secondary)
#endif
            }
            .width(60)
            .leading_alignment()

#if  NO_TABLECOLUMNFOREACH
                let propertyHeaders = self.columns.map { $0.str }
                TableColumn(Text(propertyHeaders.joined(separator: "  |  "))) { (g: Geometry) in
                    HStack {
                        ForEach(propertyHeaders, id: \.self) { h in
                            Text(g.property[h] ?? "-")
                                .frame(width: 140, alignment: .leading)
                            Divider()
                        }
                    }
                }
                .width(min: 140, max: .infinity)
                .leading_alignment()
#else
                TableColumnForEach(columns) { col in
                    TableColumn(col.str) { (g: Geometry) in
                        Text(g.property[col.str] ?? "")
                    }
                    .width(60)
                    .trailing_alignment()
                }
#endif

        } rows: {
            Section {
                ForEach(sorted_geometries()) { g in
                    TableRow(g)
                }
            }
        }
    }

    func sorted_geometries() -> [Geometry] {
        geometries.sorted(using: sortOrder)
    }
}
//#Preview {
//    GeometriesTable()
//}
