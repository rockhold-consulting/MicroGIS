//
//  GeometriesTable.swift
//  MicroGIS
//
//  Copyright 2024, Michael Rockhold (dba Rockhold Software)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  The license is provided with this work, or you may obtain a copy
//  of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//  Created by Michael Rockhold on 6/5/24.
//

import SwiftUI
import CoreLocation
import CoreData

extension Geometry {

    enum PropertyError: Error {
        case MalformedGeometry
    }

    func propertyValue(header: String) -> Any? {

        if let targetFp = feature?.properties?.first(where: { element in
            guard let fp = element as? FeatureProperty else { return false }
            return fp.key == header
        }) as? FeatureProperty {
            if let v = targetFp.primitiveValue(forKey: "value") {
                return v
            } else {
                // TODO: log error, we found a FeatureProperty with this key but it has no value
                return nil
            }
        } else {
            // not an error
            return nil
        }
    }
}

extension TableColumnContent {

    public func trailing_alignment() -> some TableColumnContent<Self.TableRowValue, Self.TableColumnSortComparator> {

        if #unavailable(macOS 14.4, iOS 17.2) {
            // Fallback on earlier versions
            return self
        } else {
            return alignment(.trailing)
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

extension Set<Geometry> {
    var idSet: Set<Geometry.ID> {
        return Set<Geometry.ID>( self.map { g in
            g.id
        })
    }
}

struct GeometriesTable: View {

    static let maxPropertyColumns = 6

    let geometries: [Geometry]
    let propertyColumns: ArraySlice<String>
    @Binding var selection: Set<Geometry>
    let idMap: [Geometry.ID: Geometry]
    @State private var sortOrder = [KeyPathComparator(\Geometry.shortName, order: .forward)]
    let jsonValueFormatter = JSONValueFormatter()

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

    init(geometries: [Geometry],
         columns: [String],
         selection: Binding<Set<Geometry>>) {

        self.geometries = geometries
        self.propertyColumns = columns[0..<min(Self.maxPropertyColumns, columns.count)]
        self._selection = selection
        self.idMap = [Geometry.ID: Geometry](uniqueKeysWithValues: geometries.map { g in
            return (g.id, g)
        })
    }

    var body: some View {
            List(geometries, selection: proxyBinding) { g in

                HStack {
                    Image(systemName: g.iconSymbolName)
                        .frame(width: 20, alignment: .center)

                    Text(g.shortName)

                    Text(g.coordString)
                        .monospacedDigit()

//                    HStack {
//                        ForEach(self.propertyColumns, id: \.self) { h in
//                            Text(propertyColumnName(idx:0))
//                            Text(propertyColumnValue(idx:0, geometry:g))
//
//                            Text(self.jsonValueFormatter.string(for: g.property[h]) ?? "-")
//                                .frame(width: 140, alignment: .leading)
//                            Divider()
//                        }
//                    }

                }
        }

//        Table(geometries.sorted(using: sortOrder),
//              selection: proxyBinding,
//              sortOrder: $sortOrder) {
//            TableColumn(" ", value: \.rawShapeCode) { g in
//                Image(systemName: g.iconSymbolName)
//                    .frame(width: 20, alignment: .center)
//            }
//            .width(20)
//
//            TableColumn("ObjID", value: \.shortName) { g in
//                Text(g.shortName)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .layoutPriority(1)
//            }
//            .width(60)
//            .leading_alignment()
//
//            TableColumn("Latitude", value: \.centerLatitude) { g in
//                Text(g.centerLatitude, format: .number.precision(Decimal.FormatStyle.Configuration.Precision.fractionLength(0..<9)))
//                    .monospacedDigit()
//            }
//            .width(100)
//
//            TableColumn("Longitude", value: \.centerLongitude) { g in
//                Text(g.centerLongitude, format: .number.precision(Decimal.FormatStyle.Configuration.Precision.fractionLength(0..<9)))
//                    .monospacedDigit()
//            }
//            .width(100)
//
//
//#if  NO_TABLECOLUMNFOREACH
//
//            TableColumn(Text(propertyColumnName(idx:0))) { g in
//                Text(propertyColumnValue(idx:0, geometry:g))
//            }
//            .width(min: 0, max: propertyColumnWidth(idx: 0))
//
//            TableColumn(Text(propertyColumnName(idx:1))) { g in
//                Text(propertyColumnValue(idx:1, geometry:g))
//            }
//            .width(min: 0, max: propertyColumnWidth(idx: 1))
//
//            TableColumn(Text(propertyColumnName(idx:2))) { g in
//                Text(propertyColumnValue(idx:2, geometry:g))
//            }
//            .width(min: 0, max: propertyColumnWidth(idx: 2))
//
//            TableColumn(Text(propertyColumnName(idx:3))) { g in
//                Text(propertyColumnValue(idx:3, geometry:g))
//            }
//            .width(min: 0, max: propertyColumnWidth(idx: 3))
//
//            TableColumn(Text(propertyColumnName(idx:4))) { g in
//                Text(propertyColumnValue(idx:4, geometry:g))
//            }
//            .width(min: 0, max: propertyColumnWidth(idx: 4))
//
//            TableColumn(Text(propertyColumnName(idx:5))) { g in
//                Text(propertyColumnValue(idx:5, geometry:g))
//            }
//            .width(min: 0, max: propertyColumnWidth(idx: 5))
//#else
//            TableColumnForEach(self.columns) { col in
//                TableColumn(col) { (g: Geometry) in
//                    Text(g.property[col] ?? "")
//                }
//                .width(60)
//                .trailing_alignment()
//            }
//#endif
//        }
    }

    func propertyColumnName(idx: Int) -> String {
        guard (0..<self.propertyColumns.count).contains(idx) else {
            return ""
        }

        return self.propertyColumns[idx]
    }

    func propertyColumnWidth(idx: Int) -> CGFloat {
        guard (0..<self.propertyColumns.count).contains(idx) else {
            return 0.0
        }
        return .infinity
    }

    func propertyColumnValue(idx: Int, geometry g: Geometry) -> String {
        let h = propertyColumnName(idx: idx)
        return self.jsonValueFormatter.string(for: g.propertyValue(header: h) ?? "") ?? ""
    }
}
