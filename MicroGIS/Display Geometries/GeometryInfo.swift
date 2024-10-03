//
//  GeometryInfo.swift
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
//  Created by Michael Rockhold on 7/17/24.
//

import SwiftUI

extension Geometry {
    var featureID: String {
        get {
            self.feature!.featureID ?? ""
        }
        set {
            self.feature!.featureID = newValue
        }
    }

    var featureProperties: [FeatureProperty] {
        return self.feature?.properties?.allObjects.compactMap({ thingy in
            thingy as? FeatureProperty
        }) ?? []
    }
}

struct GeometryInfo: View {
    @Environment(\.managedObjectContext) private var viewContext
    let geometry: Geometry

    init(geometry: Geometry) {
        self.geometry = geometry
    }

    private func doSave() {
        do {
            try viewContext.save()
        } catch {
            fatalError()
        }
    }

    var body: some View {
        Form {
            Section(header: Text("Location")) {
                ForEach([geometry]) { g in // this loop is a hack, because I don't really understand the view update lifecycle, or when state is invalidated, or something
                    GeometryLocationView(geometry: g, saver: doSave)
                }
            }

            Section(header: Text("Feature Attributes")) {
                Section {
                    // TODO: turns out you can't be sure of this feature being non-nil; in fact the geometry itself may have been deleted....
                    ForEach([geometry.feature!]) {
                        FeatureInfoView(feature: $0, saver: doSave)
                    }
                }
                Section(header: Text("Properties")) {
                    ForEach(geometry.featureProperties.sorted(by: { e1, e2 in
                        return e1.key! < e2.key!
                    }), id:\.self) { fp in
                        switch fp {
                        case let sfp as StringFeatureProperty:
                            StringField(stringFeatureProperty: sfp, submitter: doSave)

                        case let bfp as BoolFeatureProperty:
                            BoolField(boolFeatureProperty: bfp, submitter: doSave)

                        case let ifp as IntFeatureProperty:
                            IntField(intFeatureProperty: ifp, submitter: doSave)

                        case let dfp as DoubleFeatureProperty:
                            DoubleField(doubleFeatureProperty: dfp, submitter: doSave)

                        case let dtfp as DateFeatureProperty:
                            DateField(dateFeatureProperty: dtfp, submitter: doSave)

                        case let nfp as NullFeatureProperty:
                            NullField(nullFeatureProperty: nfp, submitter: {})

                        default:
                            OtherField(featureProperty: fp, submitter: {})
                        }
                    }
                }
            }

        }
    }
}
