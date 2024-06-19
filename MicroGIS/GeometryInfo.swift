//
//  GeometryInfo.swift
//  MicroGIS
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
}


struct FeatureProperty: Identifiable {
    var title: String
    var value: Any
    var id: String { title }
}

class FeaturePropertyList: ObservableObject {
    @Published var properties = [FeatureProperty]()
}

struct GeometryInfo: View {
    @Environment(\.managedObjectContext) private var viewContext

    @Binding var geometries: Set<Geometry>
    @ObservedObject private var featureProperties = FeaturePropertyList()

    var g0: Geometry {
        geometries.first!
    }

    private let jsonValueFormatter = JSONValueFormatter()

    init(geometries: Binding<Set<Geometry>>) {
        self._geometries = geometries

        if let geometry = geometries.wrappedValue.first, let props = geometry.feature!.properties {
            for p in props.data {
                self.featureProperties.properties.append(FeatureProperty(title: p.key, value: p.value))
            }
        }
    }

    var featureIDProxy: Binding<String> {
        Binding<String> {
            self.geometries.first?.featureID ?? ""
        } set: { newValue in
            self.geometries.first?.feature?.featureID = newValue
        }
    }


    var body: some View {
        switch geometries.count {
        case 0:
            Text("Select geometries in the table or the map.")
                .padding(20)

            Spacer()

        case 1:
            ScrollView {
                Form {
                    Section(header: Text("Feature Info")) {
                        TextField("Feature ID", text: featureIDProxy)
                            .onSubmit {
                                do {
                                    g0.featureID = featureIDProxy.wrappedValue
                                    try viewContext.save()
                                } catch {
                                    fatalError()
                                }
                            }
                            .disableAutocorrection(true)
                            .border(.secondary)
                        
                        ForEach($featureProperties.properties, id:\.title) { $featureProperty in
                            TextField(featureProperty.title,
                                      value: $featureProperty.value, 
                                      formatter: jsonValueFormatter)
                            .onSubmit {
                                do {
                                    let dummy = featureProperty
                                    print(dummy)
                                    try viewContext.save()
                                } catch {
                                    fatalError()
                                }
                            }
                            .disableAutocorrection(true)
                            .border(.secondary)
                        }
                    }
                    
                    Section(header: Text("Location")) {
                        
                    }
                    
                    Section(header: Text("Other Stuff")) {
                        
                    }
                }
            }
                .padding(20)

        default:
            Text("multiple (\(geometries.count)) geometries selected")
                .padding(20)
            Spacer()
        }
    }
}

//#Preview {
//    GeometryInfo()
//}
