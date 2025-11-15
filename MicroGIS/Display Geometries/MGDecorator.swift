//
//  MGDecorator.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 10/13/24.
//

import Foundation
import MapKit

protocol AnnotationDecorator {
    func decorate(view: MRMapAnnotationView) -> MRMapAnnotationView
}

protocol Renderable: Geometry {
    associatedtype RendererType: MKOverlayPathRenderer
    func makeRenderer(isSelected: Bool) -> RendererType
}

//===============================================================================
// Extensions to Geometry, but not MGPoint

extension MGPolyline: Renderable {
    func makeRenderer(isSelected: Bool) -> MKPolylineRenderer {
        return MGPolylineDecorator(polyline: self, isSelected: isSelected).renderer
    }
}

extension MGPolygon: Renderable {
    func makeRenderer(isSelected: Bool) -> MGPolygonDecorator.RendererType {
        return MGPolygonDecorator(polygon: self, isSelected: isSelected).renderer
    }
}

extension MGCircle: Renderable {
    func makeRenderer(isSelected: Bool) -> MKCircleRenderer {
        return MGCircleDecorator(circle: self, isSelected: isSelected).renderer
    }

}

extension MGMultiPolyline: Renderable {
    func makeRenderer(isSelected: Bool) -> MKMultiPolylineRenderer {
        return MGMultiPolylineDecorator(multiPolyline: self, isSelected: isSelected).renderer
    }
}

extension MGMultiPolygon: Renderable {
    func makeRenderer(isSelected: Bool) -> MKMultiPolygonRenderer {
        return MGMultiPolygonDecorator(multiPolygon: self, isSelected: isSelected).renderer
    }
}

//===============================================================================
// MGDecorator and its various Geometry-specific subclasses

public class MGDecorator {

    static var annotationImage = kitImage(symbolName: "mappin.circle",
                                         accessibilityDescription: "Map pin inside a circle")

    static let selectedAnnotationImage = kitImage(symbolName: "mappin.circle.fill",
                                         accessibilityDescription: "Selected Map pin inside a circle")

    static let clusterAnnotationImage = kitImage(symbolName: "seal",
                                                accessibilityDescription: "star-like shape")


#if os(macOS)
    static func kitImage(symbolName: String, accessibilityDescription: String) -> NSImage {
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityDescription) 
                    ?? NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "uh oh")!
        image.size = NSSize(width: 50, height: 50)
        return image
    }
#elseif os(iOS)
    static func kitImage(symbolName: String, accessibilityDescription: String) -> UIImage {
        let image = UIImage(systemName: symbolName) 
                    ?? UIImage(systemName: "exclamationmark.triangle")!
        return image.withConfiguration(UIImage.SymbolConfiguration(pointSize: 50))
    }
#endif

    static func clusterImage(memberCount: Int) -> KitImage {
        return kitImage(symbolName: "\(memberCount).circle", accessibilityDescription: "encircled number")
    }


    let isSelected: Bool
    fileprivate let _geometry: Geometry
    fileprivate let _renderer: MKOverlayRenderer!

    var fillColor: Kolor? = nil
    var strokeColor: Kolor? = nil
    var lineWidth: Float? = nil


    fileprivate init(geometry: Geometry,
                     renderer: MKOverlayRenderer,
                     isSelected: Bool) {
        self._geometry = geometry
        self._renderer = renderer
        self.isSelected = isSelected
        
        self.apply(styles: Stylesheet.defaultStyles())
        self.apply(styles: geometry.feature?.collection?.stylesheet?.styles())
        self.apply(styles: geometry.feature?.stylesheet?.styles())
        self.apply(styles: geometry.stylesheet?.styles())
        
        self.applySelection()
    }

    func apply(styles: [Style]?) {
        guard let r = _renderer as? MKOverlayPathRenderer, let ss = styles else {
            return
        }
        for s in ss {
            if s.predicate?.evaluate(with: self._geometry) ?? true { // apply the style if the predicate evals to true, or if it's nil
                // TODO: handle marker symbols
                // markersize, markerSymbol, markerColor
                
                r.strokeColor = Kolor(red: CGFloat(s.strokeColor.0) / 255.0,
                                      green: CGFloat(s.strokeColor.1) / 255.0,
                                      blue: CGFloat(s.strokeColor.2) / 255.0,
                                      alpha: CGFloat(s.strokeOpacity))
                r.fillColor = Kolor(red: CGFloat(s.fillColor.0) / 255.0,
                                      green: CGFloat(s.fillColor.1) / 255.0,
                                      blue: CGFloat(s.fillColor.2) / 255.0,
                                      alpha: CGFloat(s.fillOpacity))
                
                r.lineWidth = CGFloat(s.strokeWidth)
            }
        }
    }
    
    func applySelection() {
        // TODO: selection
        if let r = _renderer as? MKOverlayPathRenderer, isSelected {
            r.strokeColor = Kolor.black
        }
    }
}

class MGClusterDecorator: AnnotationDecorator {

    let annotation: MKClusterAnnotation

    init(annotation: MKClusterAnnotation) {
        self.annotation = annotation
    }

    func decorate(view: MRMapAnnotationView) -> MRMapAnnotationView {
        view.image = MGDecorator.clusterImage(memberCount: self.annotation.memberAnnotations.count)
        //            self.canShowCallout = true
        //            // Provide the left image icon for the annotation.
        //            self.leftCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "sf_icon"))
        return view
    }
}

class MGPointDecorator: MGDecorator, AnnotationDecorator {

    var point: MGPoint { self._geometry as! MGPoint }

    init(point: MGPoint, isSelected: Bool) {
        super.init(geometry: point,
                   renderer: MKOverlayRenderer(), // TODO: this does not make much sense
                   isSelected: isSelected)
    }

    func decorate(view: MRMapAnnotationView) -> MRMapAnnotationView {
        view.clusteringIdentifier = "pointcluster" // TODO: this is _very_ temporary

            // Provide the annotation view's image.
//        view.image = isSelected ? Self.selectedAnnotationImage : Self.annotationImage

        #if os(macOS)
        var config = NSImage.SymbolConfiguration(textStyle: .body, scale: .large)
        config = isSelected 
        ? config.applying(.init(paletteColors: [.black, .systemRed]))
        : config.applying(.init(paletteColors: [.black, .black]))
        let image = Self.annotationImage.withSymbolConfiguration(config)
        image!.size = NSSize(width: 25, height: 25)
        view.image = image
        #endif

        #if os(iOS)
        let templateImage = Self.annotationImage.withRenderingMode(.alwaysTemplate)
        view.image = templateImage
        view.tintColor = isSelected ? UIColor.red : UIColor.black
        #endif

//        let templateImage = Self.annotationImage.imageWithRenderingMode(.al)
//        view.image = templateImage
//        view.tintColor = NSColor.systemRed

        //view.setSelected(isSelected, animated: true) // TODO: should we be telling MapKit about selection?

            //            annotationView.canShowCallout = true
            //            // Provide the left image icon for the annotation.
            //            annotationView.leftCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "sf_icon"))

            //            let image = #imageLiteral(resourceName: "flag")
            // Offset the flag annotation so that the flag pole rests on the map coordinate.
            //            let offset = CGPoint(x: image.size.width / 2, y: -(image.size.height / 2) )
            //            annotationView.centerOffset = offset


        return view
    }
}


class MGPolylineDecorator: MGDecorator {
    init(polyline: MGPolyline, isSelected: Bool) {
        super.init(geometry: polyline,
                   renderer: MKPolylineRenderer(polyline: polyline.isGeodesic 
                                                ? MKGeodesicPolyline(from: polyline)
                                                : MKPolyline(from: polyline)),
                   isSelected: isSelected)
    }

    var geometry: MGPolyline { return self._geometry as! MGPolyline }
    var renderer: MKPolylineRenderer { return self._renderer as! MKPolylineRenderer }
}

class MGPolygonDecorator: MGDecorator {
    typealias RendererType = MKPolygonRenderer

    init(polygon: MGPolygon, isSelected: Bool) {
        super.init(geometry: polygon,
                   renderer: MKPolygonRenderer(polygon: MKPolygon(from: polygon)),
                   isSelected: isSelected)
    }

    var geometry: MGPolygon { return self._geometry as! MGPolygon }
    var renderer: MKPolygonRenderer { return self._renderer as! MKPolygonRenderer }
}

class MGCircleDecorator: MGDecorator {

    init(circle: MGCircle, isSelected: Bool) {
        super.init(geometry: circle,
                   renderer: MKCircleRenderer(circle: MKCircle(from: circle)),
                   isSelected: isSelected)
    }

    var geometry: MGCircle { return self._geometry as! MGCircle }
    var renderer: MKCircleRenderer { return self._renderer as! MKCircleRenderer }
}

class MGMultiPolylineDecorator: MGDecorator {

    init(multiPolyline: MGMultiPolyline, isSelected: Bool) {
        super.init(geometry: multiPolyline,
                   renderer: MKMultiPolylineRenderer(multiPolyline: MKMultiPolyline(from: multiPolyline)),
                   isSelected: isSelected)
    }

    var geometry: MGMultiPolyline { return self._geometry as! MGMultiPolyline }
    var renderer: MKMultiPolylineRenderer { return self._renderer as! MKMultiPolylineRenderer }
}

class MGMultiPolygonDecorator: MGDecorator {

    init(multiPolygon: MGMultiPolygon, isSelected: Bool) {
        super.init(geometry: multiPolygon,
                   renderer: MKMultiPolygonRenderer(multiPolygon: MKMultiPolygon(from: multiPolygon)),
                   isSelected: isSelected)
    }

    var geometry: MGMultiPolygon {
        return self._geometry as! MGMultiPolygon
    }
    var renderer: MKMultiPolygonRenderer {
        return self._renderer as! MKMultiPolygonRenderer
    }
}
