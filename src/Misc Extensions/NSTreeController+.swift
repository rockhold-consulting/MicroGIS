//
//  NSTreeController+.swift
//  SourceView
//
//  Created by Michael Rockhold on 4/4/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import Cocoa

extension NSTreeController {

    func indexPathOfObject(anObject: ModelObject) -> IndexPath? {
        return indexPathOfObject(anObject: anObject, nodes: self.arrangedObjects.children)
    }

    func indexPathOfObject(anObject: ModelObject, nodes: [NSTreeNode]!) -> IndexPath? {
        for node in nodes {
            let modelObject = node.representedObject as! ModelObject
            if anObject.identifier == modelObject.identifier {
                return node.indexPath
            }
            if node.children != nil {
                if let path = indexPathOfObject(anObject: anObject, nodes: node.children) {
                    return path
                }
            }
        }
        return nil
    }
}
