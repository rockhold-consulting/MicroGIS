//
//  MRMapCoordinator.swift
//  Georg
//
//  Created by Michael Rockhold on 5/18/24.
//

import Foundation
import MapKit

class MRMapCoordinator: NSObject, MKMapViewDelegate {

    override init() {
        super.init()
    }

    func load() {
        
    }


    weak var mapView: MKMapView? = nil {
        didSet {
            if mapView != nil {
                registerMapAnnotationViews()
            }
        }
    }

    static let geoPointReuseIdentifier = "Georg.GeoPointReuseIdentifier"
    static let clusterAnnotationReuseIdentifier = MKMapViewDefaultClusterAnnotationViewReuseIdentifier

    let annotationImage = NSImage(systemSymbolName: "mappin.circle", // or bubble.middle.bottom
                                  accessibilityDescription: "Map pin inside a circle")!

    let clusterAnnotationImage = NSImage(systemSymbolName: "seal",
                                         accessibilityDescription: "star-like shape")!


    private func registerMapAnnotationViews() {
        mapView?.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.geoPointReuseIdentifier)
        mapView?.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: Self.clusterAnnotationReuseIdentifier)
    }

}
