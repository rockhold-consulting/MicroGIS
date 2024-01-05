/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The primary view controller that contains the NSOutlineView and NSTreeController.
*/

import Cocoa
import UniformTypeIdentifiers // for UTType

class OutlineViewController: NSViewController,
    							NSTextFieldDelegate, // To respond to the text field's edit sending.
								NSUserInterfaceValidations { // To enable/disable menu items for the outline view.
    
    @objc dynamic var documentContext: NSManagedObjectContext!
    var viewModel: OutlineViewModel!
    
    // MARK: Outlets
    
    // The data source backing of the NSOutlineView.
    @IBOutlet weak var treeController: NSTreeController!

    @IBOutlet weak var outlineView: OutlineView!
    
	@IBOutlet private weak var placeHolderView: NSView!
    
    // MARK: Instance Variables
    
    // The observer of the tree controller when its selection changes using KVO.
    public private(set) var treeControllerObserver: NSKeyValueObservation?
        
  	var rowToAdd = -1 // The addition of a flagged row (for later renaming).
    
    // The directory for accepting promised files.
    lazy var promiseDestinationURL: URL = {
        let promiseDestinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Drops")
        try? FileManager.default.createDirectory(at: promiseDestinationURL, withIntermediateDirectories: true, attributes: nil)
        return promiseDestinationURL
    }()

    private var iconViewController: IconViewController!
    private var mapViewController: MapViewController!
    private var multipleItemsViewController: NSViewController!

    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Determine the contextual menu for the outline view.
        outlineView.customMenuDelegate = self
        
        // Dragging items out: Set the default operation mask so you can drag (copy) items to outside this app, and delete them in the Trash can.
        outlineView?.setDraggingSourceOperationMask([.copy, .delete], forLocal: false)
        
        // Register for drag types coming in to receive file promises from Photos, Mail, Safari, and so forth.
        outlineView.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        
        /** Disclose the two root outline groups (Places and Pictures) at first launch.
         With all subsequent launches, the autosave disclosure states determine these disclosure states.
         */
        let defaults = UserDefaults.standard
        let initialDisclosure = defaults.string(forKey: "initialDisclosure")
        if initialDisclosure == nil && treeController.arrangedObjects.children?.count ?? 0 > 0 {
            outlineView.expandItem(treeController.arrangedObjects.children![0])
            outlineView.expandItem(treeController.arrangedObjects.children![1])
            defaults.set("initialDisclosure", forKey: "initialDisclosure")
        }
    }
    
    override func viewWillAppear() {
        
        if let docContext = (view.window?.windowController as? WindowController)?.documentContext {
            documentContext = docContext
            viewModel = OutlineViewModel(context: documentContext, treeController: treeController)
            
            viewModel.load()
        }

        // Load the icon view controller from the storyboard for later use as your Detail view.
        iconViewController =
            storyboard!.instantiateController(withIdentifier: "IconViewController") as? IconViewController
        iconViewController.view.translatesAutoresizingMaskIntoConstraints = false
                        
        // Load the map view controller from the storyboard for later use as your Detail view.
        mapViewController = storyboard!.instantiateController(identifier: "MapViewController") { coder in
            return MapViewController(coder: coder, docContext: self.documentContext)
        }
        mapViewController.view.translatesAutoresizingMaskIntoConstraints = false

        // Load the multiple items selected view controller from the storyboard for later use as your Detail view.
        multipleItemsViewController =
            storyboard!.instantiateController(withIdentifier: "MultipleSelection") as? NSViewController
		multipleItemsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        
        /** Note: The following makes the outline view appear with gradient background and proper
         	selection to behave like the Finder sidebar, iTunes, and so forth.
         */
        //outlineView.selectionHighlightStyle = .sourceList // But you already do this in the storyboard.
        
        // Set up observers for the outline view's selection, adding items, and removing items.
        setupObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.addFolder),
            object: nil)
        NotificationCenter.default.removeObserver(
            self,
    		name: Notification.Name(WindowViewController.NotificationNames.removeItem),
   			object: nil)
    }
    
    // MARK: Removal and Addition

    private func removalConfirmAlert(_ itemsToRemove: [Node]) -> NSAlert {
        let alert = NSAlert()
        
        var messageStr: String
        if itemsToRemove.count > 1 {
            // Remove multiple items.
            alert.messageText = NSLocalizedString("remove multiple string", comment: "")
        } else {
            // Remove the single item.
            messageStr = NSLocalizedString("remove confirm string", comment: "")
            alert.messageText = String(format: messageStr, itemsToRemove[0].title ?? "some item(s)")
        }
        
        alert.addButton(withTitle: NSLocalizedString("ok button title", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("cancel button title", comment: ""))
        
        return alert
    }
    
    // The system calls this from handleContextualMenu() or the remove button.
    func removeItems(_ itemsToRemove: [Node]) {
        // Confirm the removal operation.
        let confirmAlert = removalConfirmAlert(itemsToRemove)
        confirmAlert.beginSheetModal(for: view.window!) { returnCode in
            if returnCode == NSApplication.ModalResponse.alertFirstButtonReturn {
                // Remove the specified set of node objects from the tree controller.
                var indexPathsToRemove = [IndexPath]()
                for item in itemsToRemove {
                    if let indexPath = self.treeController.indexPathOfObject(anObject: item) {
                    	indexPathsToRemove.append(indexPath)
                    }
                }
                self.treeController.removeObjects(atArrangedObjectIndexPaths: indexPathsToRemove)
                
                // Remove the current selection after the removal.
                self.treeController.setSelectionIndexPaths([])
            }
        }
    }
    
    // Remove the currently selected items.
    private func removeItems() {
        var nodesToRemove = [Node]()
        
        for item in treeController.selectedNodes {
            if let node = OutlineViewModel.node(from: item) {
                nodesToRemove.append(node)
            }
        }
        removeItems(nodesToRemove)
    }
 
/// - Tag: Delete
    // The user chose the Delete menu item or pressed the Delete key.
    @IBAction func delete(_ sender: AnyObject) {
        removeItems()
    }
    
    // The system calls this from handleContextualMenu() or the add group button.
   func addFolderAtItem(_ item: NSTreeNode) {
        // Obtain the base node at the specified outline view's row number, and the indexPath of that base node.
        guard let rowItemNode = OutlineViewModel.node(from: item),
            let itemNodeIndexPath = treeController.indexPathOfObject(anObject: rowItemNode) else { return }
    
        // You're inserting a new group folder at the node index path, so add it to the end.
        let indexPathToInsert = itemNodeIndexPath.appending(rowItemNode.children!.count)
    }
    
    // MARK: Notifications
    
    private func setupObservers() {
        // A notification to add a folder.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(addFolder(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.addFolder),
            object: nil)
                
        // A notification to remove an item.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(removeItem(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.removeItem),
            object: nil)
        
        // Listen to the treeController's selection change so you inform clients to react to selection changes.
        treeControllerObserver =
            treeController.observe(\.selectedObjects, options: [.new]) {(treeController, change) in
                            // Post this notification so other view controllers can react to the selection change.
                            // Interested view controllers are: WindowViewController and SplitViewController.
                            NotificationCenter.default.post(
                                name: Notification.Name(OutlineViewModel.NotificationNames.selectionChanged),
                                object: treeController)
                
                            // Save the outline selection state for later when the app relaunches.
                            self.invalidateRestorableState()
        				}
    }
    
    // A notification that the WindowViewController class sends to add a generic folder to the current selection.
    @objc
    private func addFolder(_ notif: Notification) {
        // Add the folder with the "untitled" title.
        let selectedRow = outlineView.selectedRow
        if let folderToAddNode = self.outlineView.item(atRow: selectedRow) as? NSTreeNode {
            addFolderAtItem(folderToAddNode)
        }
        // Flag the row you're adding (for later renaming).
        rowToAdd = outlineView.selectedRow
    }
    
    
    // A notification that the WindowViewController remove button sends to remove a selected item from the outline view.
    @objc
    private func removeItem(_ notif: Notification) {
        removeItems()
    }
    
    // MARK: NSTextFieldDelegate
    
    // For a text field in each outline view item, the user commits the edit operation.
    func controlTextDidEndEditing(_ obj: Notification) {
        // Commit the edit by applying the text field's text to the current node.
        guard let item = outlineView.item(atRow: outlineView.selectedRow) as? NSTreeNode,
            let node = OutlineViewModel.node(from: item) else { return }
        
//        if let textField = obj.object as? NSTextField {
//            node.title = textField.stringValue
//        }
    }
    
    // MARK: NSValidatedUserInterfaceItem

    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(delete(_:)) {
            return !treeController.selectedObjects.isEmpty
        }
        return true
    }

    // MARK: Detail View Management
    
    // Use this to decide which view controller to use as the detail.
    func viewControllerForSelection(_ selection: [NSTreeNode]?) -> NSViewController? {
        guard let outlineViewSelection = selection else { return nil }
        
        switch outlineViewSelection.count {
        case 0:
            // No selection.
            return nil
        case 1:
            // A single selection.
            guard let node = OutlineViewModel.node(from: outlineViewSelection[0]) else { return nil }
            switch node {
            case let layer as GeoLayer:
                return iconViewController
                
            case let feature as GeoFeature:
                if feature.overlays?.count == 1 {
                    if let geometry1 = feature.overlays?.anyObject() as? GeoOverlay {
                        mapViewController.mapView.setCenter(geometry1.coordinate, animated: true)
                    }
                    return mapViewController
                } else {
                    return iconViewController
                }
                
            case let overlay as GeoOverlay:
                // It is a map data node, so center map view on its central coordinate.
                mapViewController.mapView.setCenter(overlay.coordinate, animated: true)
                return mapViewController
                
            default:
                return iconViewController
            }
                
        default:
            // The selection is multiple or more than one.
            return multipleItemsViewController
        }
    }
    
    // MARK: File Promise Drag Handling

    /// The queue for reading and writing file promises.
    lazy var workQueue: OperationQueue = {
        let providerQueue = OperationQueue()
        providerQueue.qualityOfService = .userInitiated
        return providerQueue
    }()
    
}

