import SwiftUI
import CoreLocation

extension Feature {
    var geoInfo: (KitImage, String, String) {
        let cf = CoordinateFormatter(style: .Decimal)
        
        guard let geo0 = (self.kidArray as? [Geometry])?.first else {
            //        guard let geos = self.kidArray as? [Geometry], !geos.isEmpty else {
            return (
                KitImage(systemSymbolName: "dot.squareshape.split.2x2",
                         accessibilityDescription: "feature icon")!,
                "",
                ""
            )
        }
        
        let lat = geo0.wrapped?.baseInfo.coordinate.latitude ?? 0.0
        let lng = geo0.wrapped?.baseInfo.coordinate.longitude ?? 0.0
        
        return (
            geo0.icon,
            geo0.wrapped?.shape.kindString ?? "??",
            cf.string(from: CLLocationCoordinate2D(latitude: lat, longitude: lng))
        )
    }
    
    func cleanProperties() -> [String:String] {
        func clean(_ v: Any) -> String {
            switch v {
            case let s as String:
                return s
            case let i as Int:
                return String(i)
            case let d as Double:
                return String(d)
            case _ as NSNull:
                return "null"
            default:
                return "-??-"
            }
        }
        
        var props = [String:String]()
        if let p = self.properties {
            for (k,v) in p.data {
                props[k] = clean(v)
            }
        }
        return props
    }
    
}

struct FeatureTable: View {
    let managedObjectContext: NSManagedObjectContext
    let features: [Feature]
    let columns: [String]
    
    init(managedObjectContext: NSManagedObjectContext, featureIDs: Set<NSManagedObjectID>) {
        self.managedObjectContext = managedObjectContext
        self.features = featureIDs.map { fID in
            return managedObjectContext.object(with: fID) as! Feature
        }
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
            let info = feature.geoInfo
            GridRow {
                
                HStack {
                    Text(feature.objectID.shortName)
                    Divider()
                }
                NavigationLink(value: feature) {
                    HStack {
                        Image(nsImage: info.0)
                        Text(info.1) // shapeName
                    }
                }
                HStack {
                    Divider()
                    Text(info.2) // formatted coordinate of centerpoint
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
