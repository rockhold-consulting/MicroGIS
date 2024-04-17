//
//  GeoObject+.swift
//  GeorgB
//
//  Created by Michael Rockhold on 3/21/24.
//

import Foundation
#if os(macOS)
import Cocoa
public typealias KitImage = NSImage
#elseif os(iOS)
import UIKit
public typealias KitImage = UIImage
#endif

extension GeoObject {

    public var objectIdentifier: ObjectIdentifier {
        return ObjectIdentifier(self)
    }

    var icon: KitImage {
#if os(macOS)
        return NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "geoobject icon")!
#elseif os(iOS)
        return UIImage(systemName: "rectangle.3.group")!
#endif
    }
}
