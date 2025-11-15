//
//  DetailView.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 11/1/24.
//

import SwiftUI

struct DetailView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var selection: Set<GeometryItem.ID>
    @Binding var geometryColumns: [String]
    
    init(selection: Binding<Set<GeometryItem.ID>>, geometryColumns: Binding<[String]>) {
        self._selection = selection
        self._geometryColumns = geometryColumns
    }
    
    var body: some View {
        
        switch selection.count {
        case 0:
            Text("Select geometries in the table or the map.")
                .padding(20)
            
        case 1:
            GeometryInfo(geometry: viewContext.geometry(for: selection.first!))
            
        default:
            GeometriesInfo(geometriesViewModel: GeometriesViewModel(context: viewContext,
                                                                    geometryIDs: selection,
                                                                    properties: self.geometryColumns))
        }
    }
}

//#Preview {
//    DetailView()
//}
