import SwiftUI
import CoreLocation

struct FeatureTable: View {
    let managedObjectContext: NSManagedObjectContext
    let featureIDs: Set<NSManagedObjectID>
    let features: [Feature]
    let columns: [String]

    init(managedObjectContext: NSManagedObjectContext, featureIDs: Set<NSManagedObjectID>) {
        self.managedObjectContext = managedObjectContext
        self.featureIDs = featureIDs
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
    }

    struct Header: View {
        let columns: [String]
        var body: some View {
            GridRow {
                Color.clear
                    .gridCellUnsizedAxes([.horizontal, .vertical])
                ForEach(columns, id:\.self) { column in
                    Text(column)
                }
            }
        }
    }

    struct Row: View {
        struct GeometryViewModel: Identifiable, Hashable {
            let id = UUID()
            let icon: KitImage
            let shapeName: String
            let latitude: Double
            let longitude: Double

            var coordinateStr: String {
                let cf = CoordinateFormatter(style: .Decimal)
                return cf.string(from: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
        }

        let feature: Feature
        let cleanProperties: [String:String]
        let columns: [String]
        
        init(feature f: Feature, columns cc: [String]) {
            self.feature = f
            self.columns = cc
                .sorted(using: .localizedStandard)
//            self.geometryVMs = ((f.kidArray as? [Geometry]) ?? []).map { (g: Geometry) in
//                GeometryViewModel(
//                    icon: g.icon,
//                    shapeName: g.wrapped?.shape.kindString ?? "??",
//                    latitude: g.wrapped?.baseInfo.coordinate.latitude ?? 0.0,
//                    longitude: g.wrapped?.baseInfo.coordinate.longitude ?? 0.0
//                )
//            }
            var props = [String:String]()
            if let p = f.properties {
                for (k,v) in p.data {
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
                    props[k] = clean(v)
                }
            }
            self.cleanProperties = props
        }

        var body: some View {
            GridRow {
                Text(feature.objectID.shortName)
                ForEach(columns.sorted(using: .localizedStandard), id:\.self) { column in
                    HStack {
                        Text(self.cleanProperties[column] ?? "")
                        Spacer()
                        Divider()
                    }
                }
            }
            .padding(.leading)
        }
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {

            Grid(alignment: .topLeading) {
                Header(columns: columns)
                    .background { Color.blue }
                    .border(Color.gray, width: 1.0)

                ForEach(Array(features), id:\.self) { feature in
                    Row(feature: feature, columns: columns)
                        .border(Color(.black), width: 2.0)
                }
            }
        }
        Spacer()
    }
}
