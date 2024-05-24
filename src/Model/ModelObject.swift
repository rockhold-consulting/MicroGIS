//
//  GeoObject+.swift
//  GeorgB
//
//  Created by Michael Rockhold on 3/21/24.
//

import Foundation
#if os(macOS)
import Cocoa
import AppKit
public typealias KitImage = NSImage
#elseif os(iOS)
import UIKit
public typealias KitImage = UIImage
#endif

@objc protocol ModelObject {
    var identifier: NSObject { get } // NSManagedObjectID

    var title: String? { get set }

    @objc var isLeaf: Bool { get }

    @objc var kidArray: [ModelObject]? { get }

    var icon: KitImage { get }
}

extension NSManagedObjectID {
    @objc var shortName: String {
        let uri = self.uriRepresentation().lastPathComponent
        return uri.isEmpty ? "---" : uri
    }
}
