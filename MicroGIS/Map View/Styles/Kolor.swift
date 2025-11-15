//
//  Kolor.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 2025-02-02.
//

import Foundation

#if os(macOS)
import Cocoa
import AppKit
typealias KitImage = NSImage
typealias Kolor = NSColor
#elseif os(iOS)
import UIKit
typealias KitImage = UIImage
typealias Kolor = UIColor
#endif
