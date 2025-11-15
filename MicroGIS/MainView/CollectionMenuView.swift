//
//  CollectionMenuView.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 2025-02-02.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct CollectionMenuView: View {
    
    @ObservedObject var viewModel: CollectionMenuViewModel
    var featureCollections: FetchedResults<FeatureCollection>
        
    @State private var importerIsPresented = false
    @State private var importingTask: Task<Void,any Error>? = nil

    var body: some View {
        VStack {
            List(featureCollections, id: \.self, selection: $viewModel.selectedFeatureCollection) {
                Label($0.name ?? "unnamed", systemImage:"rectangle.3.group")
            }
#if os(macOS)
            .onDeleteCommand(perform: {
                withAnimation {
                    viewModel.deleteSelectedFeatureCollection()
                }
            })
#endif
            .navigationTitle(Text("Feature Collections"))
            
#if os(macOS)
            .keyboardShortcut(.delete, modifiers: [])
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Import Features", systemImage: "plus")
                    }
                }
            }
#endif
#if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Import Features", systemImage: "plus")
                    }
                }
            }
#endif
            .fileImporter(
                isPresented: $importerIsPresented,
                allowedContentTypes: [UTType(filenameExtension: "geojson", conformingTo: .json)!]
            ) { result in
                switch result {
                case .success(let file):
                    importingTask = Task.detached {
                        PersistenceController.shared.importFeaturesFile(url: file)
                        try await Task.sleep(nanoseconds: UInt64(5 * Double(NSEC_PER_SEC)))
                        await MainActor.run {
                            importingTask = nil
                        }
                    }
                case .failure(let error):
                    // TODO: handle this error
                    print(error.localizedDescription)
                }
            }
            
            if importingTask != nil {
                Spacer()
                Button("Cancel Importing") {
                    importingTask!.cancel()
                    importingTask = nil
                }.padding()
            }
        }
    }
 
    private func addItem() {
        importerIsPresented = true
    }
}

//
//#Preview {
//    CollectionMenuView(selectedFeatureCollection: <#Binding<FeatureCollection?>#>)
//}
