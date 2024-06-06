//
//  DocumentView.swift
//  Georg
//
//  Created by Michael Rockhold on 5/16/24.
//

import SwiftUI
import CoreData

struct FakeStyleManager: Hashable {
    static func == (lhs: FakeStyleManager, rhs: FakeStyleManager) -> Bool {
        return lhs.name == rhs.name
    }

    let name: String
    init(name: String) {
        self.name = name
    }
}

enum Panel: Hashable {
    case styleManager(FakeStyleManager)
    case feature(Feature)
}

struct DocumentView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest<Feature>(sortDescriptors: [SortDescriptor(\.objectID.shortName)])
    private var features: FetchedResults<Feature>
    @State private var selection: Set<NSManagedObjectID> = []
    @State private var path = NavigationPath()

    var body: some View {
        NavigationSplitView {
            Sidebar(features: features, selection: $selection)
        } detail: {
            NavigationStack(path: $path) {
                MainContent(moc: moc, selection: $selection)
            }
        }
//        .onChange(of: selection) { _ in
//            path.removeLast(path.count)
//        }
    }
}

#Preview {
    DocumentView()
}
