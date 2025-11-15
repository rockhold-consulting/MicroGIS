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

protocol PropertyValue: Any, Equatable {}


extension Geometry {
    
    enum PropertyError: Error {
        case MalformedGeometry
    }
    
    func propertyValue(header: String) -> (any PropertyValue)? {
        
        if let targetFp = feature?.properties?.first(where: { element in
            guard let fp = element as? FeatureProperty else { return false }
            return fp.key == header
        }) as? FeatureProperty {
            if let v = targetFp.primitiveValue(forKey: "value") {
                return v as? (any PropertyValue)
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

struct GeometriesTable: View {
    @Environment(\.managedObjectContext) private var viewContext
    var geometries: [GeometryItem]
    @State var propertyColumns: [String]
    @Binding var selection: Set<GeometryItem.ID>
    
    @State private var displayingDetails = false
    
    @State private var sortOrder = [KeyPathComparator(\GeometryItem.geometry.shortName, order: .forward)]
    let jsonValueFormatter = JSONValueFormatter()
    
    init(geometries: [GeometryItem],
         columns: [String],
         selection: Binding<Set<GeometryItem.ID>>) {
        
        self.geometries = geometries
        self.propertyColumns = columns
        self._selection = selection
    }
    
    var body: some View {
        HStack {
            Text("Type")
                .frame(width: 40, alignment: .center)
            Text("obj ID")
                .offset(CGSize(width: 10, height: 0))
                .frame(width: 50, alignment: .leading)
            Text("Coordinates")
                .offset(CGSize(width: 10, height: 0))
                .frame(width: 160, alignment: .leading)
#if os(macOS)
            ForEach(self.propertyColumns, id: \.self) { h in
                Text(h)
                    .offset(CGSize(width: 10, height: 0))
                    .frame(width: 150, alignment: .leading)
            }
#endif
            Spacer()
            
        }
        
        List(geometries, selection: $selection) { g in
            HStack {
                Image(systemName: g.geometry.iconSymbolName)
                    .frame(width: 40, alignment: .center)
                
                Text(g.geometry.shortName)
                    .offset(CGSize(width: 10, height: 0))
                    .frame(width: 50, alignment: .leading)
                
                Text(g.geometry.coordString)
                    .monospacedDigit()
                    .offset(CGSize(width: 10, height: 0))
                    .frame(width: 160, alignment: .leading)
                
#if os(macOS)
                ForEach(self.propertyColumns, id: \.self) { h in
                    Text(g.propertyValueString(for: h))
                        .offset(CGSize(width: 10, height: 0))
                        .frame(width: 150, alignment: .leading)
                }
#endif
                
            }
        }
        .listStyle(.plain)
#if os(iOS)
        .toolbar {
            EditButton()
            Button("Details", systemImage: "list.dash.header.rectangle", action: details)
                .labelStyle(.iconOnly)
                .disabled(selection.isEmpty)
            
        }
        .sheet(isPresented: $displayingDetails) {
            DetailView(selection: $selection, geometryColumns: $propertyColumns)
//                .padding(20)
        }
#endif
        
        
        //        Table(self.geometries, selection: self.$selection, sortOrder: self.$sortOrder) {
        //
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
        //              .onChange(of: sortOrder) { _, sortOrder in
        //
        //              }
    }
    
    func details() {
        displayingDetails = true
    }
    
    mutating func toggleSortOrder() {
        geometries.sort(using: sortOrder.first!)
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
