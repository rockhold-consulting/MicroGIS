//
//  OutlineViewModel.swift
//  Georg
//
//  Created by Michael Rockhold on 12/18/23.
//

import Foundation
import CoreData
import AppKit

class OutlineViewModel {
    // MARK: Constants
    
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
    
    // The outline view of top-level content. NSTreeController backs this.
    @objc dynamic var contents: [AnyObject] = []

    init(context: NSManagedObjectContext, treeController: NSTreeController) {
        self.context = context
        self.treeController = treeController
        
    }
    
    public func load() {
        // Add the Places grouping and its content.
        addPlacesGroup()
        
        // Add the Pictures grouping and its outline content.
        addPicturesGroup()
    }
        
    // Unique nodeIDs for the two top-level group nodes.
    static let picturesID = "1000"
    static let placesID = "1001"
    
    private func addPlacesGroup() {
        // Add the Places outline group section.
        // Note that the system shares the nodeID and the expansion restoration ID.
        
        addGroupNode(OutlineViewModel.NameConstants.places, identifier: OutlineViewModel.placesID)
        
        // Add the Applications folder inside Places.
        let appsURLs = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask)
        addFileSystemObject(appsURLs[0], indexPath: IndexPath(indexes: [0, 0]))
        
        treeController.setSelectionIndexPath(nil) // Start back at the root level.
    }
    
    // Populate the tree controller from the disk-based dictionary (DataSource.plist).
    private func addPicturesGroup() {
        // Add the Pictures section.
        addGroupNode(OutlineViewModel.NameConstants.pictures, identifier: OutlineViewModel.picturesID)

        guard let newPlistURL = Bundle.main.url(forResource: "DataSource", withExtension: "plist") else {
            fatalError("Failed to resolve URL for `DataSource.plist` in bundle.")
        }
        do {
            // Populate the outline view with the .plist file content.
            struct OutlineData: Decodable {
                let children: [Node]
            }
            // Decode the top-level children of the outline.
            let plistDecoder = PropertyListDecoder()
            let data = try Data(contentsOf: newPlistURL)
            let decodedData = try plistDecoder.decode(OutlineData.self, from: data)
            for node in decodedData.children {
                // Recursively add further content from the specified node.
                addNode(node)
                if node.type == .container {
                    selectParentFromSelection()
                }
            }
        } catch {
            fatalError("Failed to load `DataSource.plist` in bundle.")
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
    
    // The system calls this by drag and drop from the Finder.
    func addFileSystemObject(_ url: URL, indexPath: IndexPath) {
        let node = OutlineViewController.fileSystemNode(from: url)
        treeController.insert(node, atArrangedObjectIndexPath: indexPath)
        
        if url.isFolder {
            do {
                node.identifier = NSUUID().uuidString
                // It's a folder node, so find its children.
                let fileURLs =
                    try FileManager.default.contentsOfDirectory(at: node.url!,
                                                                includingPropertiesForKeys: [],
                                                                options: [.skipsHiddenFiles])
                // Move indexPath one level deep for insertion.
                let newIndexPath = indexPath
                let finalIndexPath = newIndexPath.appending(0)
                
                addFileSystemObjects(fileURLs, indexPath: finalIndexPath)
            } catch _ {
                // No content at this URL.
            }
        } else {
            // This is just a leaf node, so there aren't any children to insert.
        }
    }

    private func addFileSystemObjects(_ entries: [URL], indexPath: IndexPath) {
        // Sort the array of URLs.
        var sorted = entries
        sorted.sort( by: { $0.lastPathComponent > $1.lastPathComponent })
        
        // Insert the sorted URL array into the tree controller.
        for entry in sorted {
            if entry.isFolder {
                // It's a folder node, so add the folder.
                let node = OutlineViewController.fileSystemNode(from: entry)
                node.identifier = NSUUID().uuidString
                treeController.insert(node, atArrangedObjectIndexPath: indexPath)
                
                do {
                    let fileURLs =
                        try FileManager.default.contentsOfDirectory(at: entry,
                                                                    includingPropertiesForKeys: [],
                                                                    options: [.skipsHiddenFiles])
                    if !fileURLs.isEmpty {
                        // Move indexPath one level deep for insertions.
                        let newIndexPath = indexPath
                        let final = newIndexPath.appending(0)
                        
                        addFileSystemObjects(fileURLs, indexPath: final)
                    }
                } catch _ {
                    // No content at this URL.
                }
            } else {
                // It's a leaf node, so add the leaf.
                addFileSystemObject(entry, indexPath: indexPath)
            }
        }
    }

    private func addGroupNode(_ folderName: String, identifier: String) {
        let node = Node()
        node.type = .container
        node.title = folderName
        node.identifier = identifier
    
        // Insert the group node.
        
        // Get the insertion indexPath from the current selection.
        var insertionIndexPath: IndexPath
        // If there is no selection, add a new group to the end of the content's array.
        if treeController.selectedObjects.isEmpty {
            // There's no selection, so add the folder to the top-level and at the end.
            insertionIndexPath = IndexPath(index: contents.count)
        } else {
            /** Get the index of the currently selected node, then add the number of its children to the path.
                This gives you an index that allows you to add a node to the end of the currently
                selected node's children array.
             */
            insertionIndexPath = treeController.selectionIndexPath!
            if let selectedNode = treeController.selectedObjects[0] as? Node {
                // The user is trying to add a folder on a selected folder, so add the selection to the children.
                insertionIndexPath.append(selectedNode.children.count)
            }
        }
        
        treeController.insert(node, atArrangedObjectIndexPath: insertionIndexPath)
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
                indexPath.append(node.children.count)
            }
        }
        
        // The child to insert has a valid URL, so use its display name as the node title.
        // Take the URL and obtain the display name (nonescaped with no extension).
        if node.isURLNode {
            node.title = node.url!.localizedName
        }
        
        // The user is adding a child node, so tell the controller directly.
        treeController.insert(node, atArrangedObjectIndexPath: indexPath)
        
        if !node.isDirectory {
            // For leaf children, select its parent for further additions.
            selectParentFromSelection()
        }
    }
    

}
