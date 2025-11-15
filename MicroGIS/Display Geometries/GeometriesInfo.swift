//
//  GeometriesInfo.swift
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
//  Created by Michael Rockhold on 8/26/24.
//

import SwiftUI

struct GeometriesInfo: View {
    let geometriesViewModel: GeometriesViewModel
    
    var body: some View {
        #if false
        Section(header: Text("Location")) {
            ForEach([geometry]) { g in // this loop is a hack, because I don't really understand the view update lifecycle, or when state is invalidated, or something
                GeometryLocationView(geometry: g, saver: viewContext.saveIfNeeded)
            }
        }

        Section(header: Text("Feature Attributes")) {
            Section {
                // TODO: turns out you can't be sure of this feature being non-nil; in fact the geometry itself may have been deleted....
                ForEach([geometry.feature!]) {
                    FeatureInfoView(feature: $0, saver: {})
                }
            }
        }
        
        Section(header: Text("Properties")) {
            Section {
                ForEach(geometry.featureProperties.sorted(by: { e1, e2 in
                    return e1.key! < e2.key!
                }), id:\.self) { fp in
                    switch fp {
                    case let sfp as StringFeatureProperty:
                        StringField(stringFeatureProperty: sfp, submitter: viewContext.saveIfNeeded)
                        
                    case let bfp as BoolFeatureProperty:
                        BoolField(boolFeatureProperty: bfp, submitter: viewContext.saveIfNeeded)
                        
                    case let ifp as IntFeatureProperty:
                        IntField(intFeatureProperty: ifp, submitter: viewContext.saveIfNeeded)
                        
                    case let dfp as DoubleFeatureProperty:
                        DoubleField(doubleFeatureProperty: dfp, submitter: viewContext.saveIfNeeded)
                        
                    case let dtfp as DateFeatureProperty:
                        DateField(dateFeatureProperty: dtfp, submitter: viewContext.saveIfNeeded)
                        
                    case let nfp as NullFeatureProperty:
                        NullField(nullFeatureProperty: nfp, submitter: {})
                        
                    default:
                        OtherField(featureProperty: fp, submitter: {})
                    }
                }
            }
        }
        #endif
        
        Text("GEOMETRIESINFO multiple (\(geometriesViewModel.geometryItems.count)) geometries selected")
    }
}
