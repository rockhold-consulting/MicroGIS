import SwiftUI
import CoreLocation

struct FeatureTable: View {
    let managedObjectContext: NSManagedObjectContext
    let features: [Feature]
    let columns: [String]
    
    init(managedObjectContext: NSManagedObjectContext, features: [Feature]) {
        self.managedObjectContext = managedObjectContext
        self.features = features
        self.columns = features.reduce(Set<String>()) { set, f in
            if let k = f.properties?.data.keys {
                return set.union(k)
            } else {
                return set
            }
        }.map { s in
            s
        }
        .sorted(using: .localizedStandard)
    }
    
    struct Header: View {
        let columns: [String]
        var body: some View {
            GridRow {
                Text("")
                    .gridColumnAlignment(.trailing)
                HStack {
                    Divider()
                    Text("Kind")
                        .gridColumnAlignment(.leading)
                }
                HStack {
                    Divider()
                    Text("Center")
                        .gridColumnAlignment(.leading)
                }
                ForEach(columns, id:\.self) { column in
                    HStack {
                        Divider()
                        Text(column)
                            .gridColumnAlignment(.leading)
                    }
                }
            }
        }
    }
    
    struct Row: View {
        
        let feature: Feature
        let columns: [String]
        
        init(feature f: Feature, columns cc: [String]) {
            self.feature = f
            self.columns = cc
        }
        
        var body: some View {
            let info = feature.geoInfo()
            GridRow {
                
                HStack {
                    Text(feature.shortName)
                    Divider()
                }
                NavigationLink(value: feature) {
                    HStack {
                        Image(nsImage: info.icon)
                        Text(info.kindName)
                    }
                }
                HStack {
                    Divider()
                    Text(info.coordString)
                }
                
                ForEach(columns, id:\.self) { column in
                    let cleanProperties = feature.cleanProperties()
                    HStack {
                        Divider()
                        Text(cleanProperties[column] ?? "")
                    }
                }
                
            }
        }
    }
    
    var body: some View {
        if !features.isEmpty {
            ScrollView([.horizontal, .vertical]) {
                Grid(alignment: .topLeading) {
                    Header(columns: columns)
                    Divider()
                    ForEach(Array(features), id:\.self) { feature in
                        Row(feature: feature, columns: columns)
                        Divider()
                    }
                }
                .padding()
            }
        }
        else {
            Text("Nothing Selected")
                .padding()
        }
    }
}
