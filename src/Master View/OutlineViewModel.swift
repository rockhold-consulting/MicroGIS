//
//  OutlineViewModel.swift
//  Georg
//
//  Created by Michael Rockhold on 12/18/23.
//

import Foundation
import CoreData
import AppKit
import Cocoa
import UniformTypeIdentifiers

@objc protocol Node: NSObjectProtocol {
    
    var title: String? { get }
    
    var identifier: String? { get }
    
    @objc var children: [Node]? { get }
    
    @objc var isLeaf: Bool { get }
        
    var isSpecialGroup: Bool { get }
        
    var icon: NSImage { get }
    
    var canChange: Bool { get }
    
    var canAddTo: Bool { get }
}

class OutlineViewModel: NSObject {
    
    // MARK: Constants
    
    struct NotificationNames {
        // A notification when the tree controller's selection changes. SplitViewController uses this.
        static let selectionChanged = "selectionChangedNotification"
    }

    struct NameConstants {
        // The default name for added folders and leafs.
        static let untitled = NSLocalizedString("untitled string", comment: "")
        // The places group title.
        static let places = NSLocalizedString("places string", comment: "")
        // The pictures group title.
        static let pictures = NSLocalizedString("pictures string", comment: "")
    }

    let context: NSManagedObjectContext
    let treeController: NSTreeController
    var fetchedGeoLayerResultsController: NSFetchedResultsController<GeoLayer>

    // The outline view of top-level content. NSTreeController backs this.
    @objc dynamic var contents: [AnyObject] = []

    init(context: NSManagedObjectContext, treeController: NSTreeController) {
        self.context = context
        self.treeController = treeController
        
        let layerReq = GeoLayer.fetchRequest()
        layerReq.sortDescriptors = [NSSortDescriptor(key: "zindex", ascending: true)]
        fetchedGeoLayerResultsController = NSFetchedResultsController(
            fetchRequest: layerReq,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        super.init()
        fetchedGeoLayerResultsController.delegate = self
    }
    
    public func load() {
        do {
            try fetchedGeoLayerResultsController.performFetch()
            loadFetchedObjects()
        }
        catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }
    
    private func loadFetchedObjects() {
        guard let layers = fetchedGeoLayerResultsController.fetchedObjects else { return }
        
        if let items = treeController.content as? [Node] {
            let indexPathsToRemove = items.map { item in
                self.treeController.indexPathOfObject(anObject: item)!
            }
            if indexPathsToRemove.count > 0 {
                self.treeController.removeObjects(atArrangedObjectIndexPaths: indexPathsToRemove)
            }
        }
        
        for layer in layers {
            print("zindex \(layer.zindex)")
            addLayerNode(layer)
        }
        treeController.setSelectionIndexPath(nil) // Start back at the root level.
    }
                    
    // Take the currently selected node and select its parent.
    private func selectParentFromSelection() {
        if !treeController.selectedNodes.isEmpty {
            let firstSelectedNode = treeController.selectedNodes[0]
            if let parentNode = firstSelectedNode.parent {
                // Select the parent.
                let parentIndex = parentNode.indexPath
                treeController.setSelectionIndexPath(parentIndex)
            } else {
                // No parent exists (you are at the top of tree), so make no selection in your outline.
                let selectionIndexPaths = treeController.selectionIndexPaths
                treeController.removeSelectionIndexPaths(selectionIndexPaths)
            }
        }
    }
                            

    // Insert a new layer into the tree
    private func addLayerNode(_ node: GeoLayer) {
        // Always add layers to the top-level and at the end, as the array of GeoLayer fetched objects is already sorted
        treeController.addObject(node)
    }
    
    private func addNode(_ node: Node) {
        // Find the selection to insert the node.
        var indexPath: IndexPath
        if treeController.selectedObjects.isEmpty {
            // No selection, so just add the child to the end of the tree.
            indexPath = IndexPath(index: contents.count)
        } else {
            // There's a selection, so insert the child at the end of the selection.
            indexPath = treeController.selectionIndexPath!
            if let node = treeController.selectedObjects[0] as? Node {
                indexPath.append(node.children!.count)
            }
        }
                
        // The user is adding a child node, so tell the controller directly.
        treeController.insert(node, atArrangedObjectIndexPath: indexPath)
        
        if node.isLeaf {
            // For leaf children, select its parent for further additions.
            selectParentFromSelection()
        }
    }
    

}

extension OutlineViewModel: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        loadFetchedObjects()
    }
}
