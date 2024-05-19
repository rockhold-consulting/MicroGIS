//
//  MRMap.swift
//  Georg
//
//  Created by Michael Rockhold on 5/18/24.
//


import SwiftUI
import MapKit


#if os(macOS)
import Cocoa
typealias BaseViewRepresentable = NSViewRepresentable
#elseif os(iOS)
import UIKit
typealias BaseViewRepresentable = UIViewRepresentable
#endif


struct MRMap: BaseViewRepresentable {

#if os(macOS)
    typealias NSViewType = MKMapView
#elseif os(iOS)
    typealias UIViewType = MKMapView
#endif

    typealias Coordinator = MRMapCoordinator

    let features: FetchedResults<Feature>
    @Binding var selection: Set<Feature>

    func makeCoordinator() -> Coordinator {
        MRMapCoordinator()
    }

    func makeNSView(context: Self.Context) -> NSViewType {
        defer {
            context.coordinator.load()
        }
        let view = MKMapView()
        view.delegate = context.coordinator
        context.coordinator.mapView = view
        return view
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        context.coordinator.load()
    }
}
//
//#Preview {
//    MRMap(features: FetchResults<Feature>().wrappedValue, selection: [])
//}
