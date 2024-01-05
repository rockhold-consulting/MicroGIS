// This file is part of Georg, a macOS/iOS program for displaying and
// editing "geofeatures" on a map.
//
// Copyright (C) 2023  Michael E. Rockhold
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https:www.gnu.org/licenses/>.
//
//  WindowController.swift
//  Georg
//    Abstract:
//    NSWindowController subclass controlling the behavior of the primary Document window.
//
//  Created by Michael Rockhold on 8/21/23.
//

import Cocoa

class WindowController: NSWindowController, NSWindowDelegate {
    
    let documentContext: NSManagedObjectContext

    required init?(coder aDecoder: NSCoder, docContext: NSManagedObjectContext) {
        
        documentContext = docContext
        
        super.init(coder: aDecoder)
        /** NSWindows loaded from the storyboard will be cascaded
         based on the original frame of the window in the storyboard.
         */
        shouldCascadeWindows = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
//    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
//        if segue.identifier == "WindowViewControllerRelationship" {
//            print("dest \(segue.destinationController)")
//        }
//        super.prepare(for: segue, sender: sender)
//    }
//    
//    
//    @IBSegueAction func prepareWindowViewControllerSegue(_ coder: NSCoder, sender: Any?, segueIdentifier: String?) -> WindowViewController? {
//                let wvc = WindowViewController(coder: coder)
//                return wvc
//    }    
}


