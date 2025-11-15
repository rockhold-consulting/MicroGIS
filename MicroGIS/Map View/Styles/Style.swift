//
//  Style.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 2025-02-01.
//

import Foundation

// This is based on v1.1.0 of the Simple Styles spec,
// https://github.com/mapbox/simplestyle-spec/blob/master/1.1.0/README.md
//
struct Style {
    enum MarkerSize {
        case small
        case medium
        case large
    }
    typealias StyleRGB = (UInt8, UInt8, UInt8)
    
    let predicate: NSPredicate?
    
    // OPTIONAL: default ""
    // A title to show when this item is clicked or
    // hovered over
    let title: String?

    // OPTIONAL: default ""
    // A description to show when this item is clicked or
    // hovered over
    let description: String?

    // OPTIONAL: default "medium"
    // specify the size of the marker. sizes
    // can be different pixel sizes in different
    // implementations
    // Value must be one of
    // "small"
    // "medium"
    // "large"
    let markerSize: MarkerSize?

    // OPTIONAL: default ""
    // a symbol to position in the center of this icon
    // if not provided or "", no symbol is overlaid
    // and only the marker is shown
    // Allowed values include
    // - Icon ID
    // - An integer 0 through 9
    // - A lowercase character "a" through "z"
    let markerSymbol: String?
    
    // OPTIONAL: default "7e7e7e"
    // the marker's color
    //
    // value must follow COLOR RULES
    let markerColor: StyleRGB

    // OPTIONAL: default "555555"
    // the color of a line as part of a polygon, polyline, or
    // multigeometry
    //
    // value must follow COLOR RULES
    let strokeColor: StyleRGB

    // OPTIONAL: default 1.0
    // the opacity of the line component of a polygon, polyline, or
    // multigeometry
    //
    // value must be a floating point number greater than or equal to
    // zero and less or equal to than one
    let strokeOpacity: Float

    // OPTIONAL: default 2
    // the width of the line component of a polygon, polyline, or
    // multigeometry
    //
    // value must be a floating point number greater than or equal to 0
    let strokeWidth: Float

    // OPTIONAL: default "555555"
    // the color of the interior of a polygon
    //
    // value must follow COLOR RULES
    let fillColor: StyleRGB

    // OPTIONAL: default 0.6
    // the opacity of the interior of a polygon. Implementations
    // may choose to set this to 0 for line features.
    //
    // value must be a floating point number greater than or equal to
    // zero and less or equal to than one
    let fillOpacity: Float
    
    static func defaultStyle() -> Style {
        return Style(
            predicate: nil,
            title: nil,
            description: nil,
            markerSize: nil,
            markerSymbol: nil,
            markerColor: StyleRGB(0x7e, 0x7e, 0x7e),
            strokeColor: StyleRGB(0x55, 0x55, 0x55),
            strokeOpacity: 1.0,
            strokeWidth: 2.0,
            fillColor: StyleRGB(0x55, 0x55, 0x55),
            fillOpacity: 0.6
            )
        }
}
