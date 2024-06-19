//
//  GeometriesTable.swift
//  Georg
//
//  Created by Michael Rockhold on 6/5/24.
//

import SwiftUI
import CoreLocation
import CoreData

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

extension Set<Geometry> {
    var idSet: Set<Geometry.ID> {
        return Set<Geometry.ID>( self.map { g in
            g.id
        })
    }
}

struct GeometriesTable: View {

    let geometries: [Geometry]
    let columns: [PropertyColumn]
    @Binding var selection: Set<Geometry>
    let idMap: [Geometry.ID: Geometry]
    @Binding var searchText: String
    @State private var sortOrder = [KeyPathComparator(\Geometry.shortName, order: .forward)]
    let jsonValueFormatter = JSONValueFormatter()

    init(geometries: [Geometry], columns: [PropertyColumn], selection: Binding<Set<Geometry>>, searchText: Binding<String>) {
        self.geometries = geometries
        self.columns = columns
        self._selection = selection
        self._searchText = searchText
        self.idMap = [Geometry.ID: Geometry](uniqueKeysWithValues: geometries.map { g in
            return (g.id, g)
        })
    }

    var proxyBinding: Binding<Set<Geometry.ID>> {
        Binding<Set<Geometry.ID>> {
            Set<Geometry.ID>(self.selection.map { $0.id })
        }
        set: { newValue in
            self.selection.removeAll()
            self.selection.formUnion(newValue.compactMap { objID in
                self.idMap[objID]
            })
        }
    }

    var body: some View {
        VStack {
            Table(geometries,
                  selection: proxyBinding,
                  sortOrder: $sortOrder) {
                TableColumn(" ", value: \.shapeCode.rawValue) { g in
                    Image(systemName: g.iconSymbolName)
                        .frame(width: 20, alignment: .center)
                }
                .width(20)
                
                TableColumn("ID", value: \.shortName) { g in
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
                //            .trailing_alignment()
                
                TableColumn("Feature ID", value: \.featureShortName) { g in
                    Text(g.featureShortName)
#if os(macOS)
                        .foregroundStyle(.secondary)
#endif
                }
                .width(60)
                //            .leading_alignment()
                
#if  NO_TABLECOLUMNFOREACH
                let propertyHeaders = self.columns.map { $0.str }
                TableColumn(Text(propertyHeaders.joined(separator: "  |  "))) { (g: Geometry) in
                    HStack {
                        ForEach(propertyHeaders, id: \.self) { h in
                            Text(self.jsonValueFormatter.string(for: g.property[h]) ?? "-")
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
            }
            Text("count: \(geometries.count), selections: \(selection.count)")
        }
    }
}
//#Preview {
//    GeometriesTable()
//}
