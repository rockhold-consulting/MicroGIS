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

    struct NotificationNames {
        // A notification when the tree controller's selection changes. SplitViewController uses this.
        static let selectionChanged = "selectionChangedNotification"
    }
    
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
    private var fileViewController: FileViewController!
    private var imageViewController: ImageViewController!
    private var mapViewController: MapViewController!
    private var multipleItemsViewController: NSViewController!

    var viewModel: OutlineViewModel? {
        didSet {
            viewModel?.load()
        }
    }


    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Determine the contextual menu for the outline view.
   		outlineView.customMenuDelegate = self
        
        // Dragging items out: Set the default operation mask so you can drag (copy) items to outside this app, and delete them in the Trash can.
        outlineView?.setDraggingSourceOperationMask([.copy, .delete], forLocal: false)
        
        // Register for drag types coming in to receive file promises from Photos, Mail, Safari, and so forth.
        outlineView.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        
        // You want these drag types: your own type (outline row number), and fileURLs.
		outlineView.registerForDraggedTypes([
      		.nodeRowPasteBoardType, // Your internal drag type, the outline view's row number for internal drags.
            NSPasteboard.PasteboardType.fileURL // To receive file URL drags.
            ])

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
                
        // Load the icon view controller from the storyboard for later use as your Detail view.
        iconViewController =
            storyboard!.instantiateController(withIdentifier: "IconViewController") as? IconViewController
        iconViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Load the file view controller from the storyboard for later use as your Detail view.
        fileViewController =
            storyboard!.instantiateController(withIdentifier: "FileViewController") as? FileViewController
        fileViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Load the image view controller from the storyboard for later use as your Detail view.
        imageViewController =
            storyboard!.instantiateController(withIdentifier: "ImageViewController") as? ImageViewController
        imageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Load the image view controller from the storyboard for later use as your Detail view.
        mapViewController =
            storyboard!.instantiateController(withIdentifier: "MapViewController") as? MapViewController
        mapViewController.view.translatesAutoresizingMaskIntoConstraints = false

        // Load the multiple items selected view controller from the storyboard for later use as your Detail view.
        multipleItemsViewController =
            storyboard!.instantiateController(withIdentifier: "MultipleSelection") as? NSViewController
		multipleItemsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        guard let rootVC = rootViewController() else {
            fatalError()
        }
        rootVC.outlineViewController = self
        rootVC.mapViewController = mapViewController
        
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
        	name: Notification.Name(WindowViewController.NotificationNames.addPicture),
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
            if itemsToRemove[0].isURLNode {
                messageStr = NSLocalizedString("remove link confirm string", comment: "")
            } else {
                messageStr = NSLocalizedString("remove confirm string", comment: "")
            }
            alert.messageText = String(format: messageStr, itemsToRemove[0].title)
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
            if let node = OutlineViewController.node(from: item) {
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
        guard let rowItemNode = OutlineViewController.node(from: item),
            let itemNodeIndexPath = treeController.indexPathOfObject(anObject: rowItemNode) else { return }
    
        // You're inserting a new group folder at the node index path, so add it to the end.
        let indexPathToInsert = itemNodeIndexPath.appending(rowItemNode.children.count)
    
        // Create an empty folder node.
        let nodeToAdd = Node()
        nodeToAdd.title = OutlineViewModel.NameConstants.untitled
        nodeToAdd.identifier = NSUUID().uuidString
        nodeToAdd.type = .container
        treeController.insert(nodeToAdd, atArrangedObjectIndexPath: indexPathToInsert)
    
        // Flag the row you're adding (for later renaming).
        rowToAdd = outlineView.row(forItem: item) + rowItemNode.children.count
    }

    // The system calls this from handleContextualMenu() or the add picture button.
    func addPictureAtItem(_ item: Node) {
        // Present an open panel to choose a picture to display in the outline view.
        let openPanel = NSOpenPanel()
        
        // Find a picture to add.
        let locationTitle = item.title
        let messageStr = NSLocalizedString("choose picture message", comment: "")
        openPanel.message = String(format: messageStr, locationTitle)
        openPanel.prompt = NSLocalizedString("open panel prompt", comment: "") // Set the Choose button title.
        openPanel.canCreateDirectories = false
        
        // Allow choosing all kinds of image files.
        if #available(macOS 11.0, *) {
            openPanel.allowedContentTypes = [UTType.image]
        } else {
            if let imageTypes = CGImageSourceCopyTypeIdentifiers() as? [String] {
                openPanel.allowedFileTypes = imageTypes
            }
        }
        
        openPanel.beginSheetModal(for: view.window!) { (response) in
            if response == NSApplication.ModalResponse.OK {
                // Create a leaf picture node.
                let node = Node()
                node.type = .document
                node.url = openPanel.url
                node.title = node.url!.localizedName
                
                // Get the indexPath of the folder you're adding to.
                if let itemNodeIndexPath = self.treeController.indexPathOfObject(anObject: item) {
                    // You're inserting a new picture at the item node index path.
                    let indexPathToInsert = itemNodeIndexPath.appending(IndexPath(index: 0))
                    self.treeController.insert(node, atArrangedObjectIndexPath: indexPathToInsert)
                }
            }
        }
    }
    
    // MARK: Notifications
    
    private func setupObservers() {
        // A notification to add a folder.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(addFolder(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.addFolder),
            object: nil)
        
        // A notification to add a picture.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(addPicture(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.addPicture),
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
                                name: Notification.Name(OutlineViewController.NotificationNames.selectionChanged),
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
    
    // A notification that the WindowViewController class sends to add a picture to the selected folder node.
    @objc
    private func addPicture(_ notif: Notification) {
        let selectedRow = outlineView.selectedRow
        
        if let item = self.outlineView.item(atRow: selectedRow) as? NSTreeNode,
            let addToNode = OutlineViewController.node(from: item) {
            	addPictureAtItem(addToNode)
        }
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
        guard let item = outlineView.item(atRow: outlineView.selectedRow),
            let node = OutlineViewController.node(from: item) else { return }
        
        if let textField = obj.object as? NSTextField {
            node.title = textField.stringValue
        }
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
        
        var viewController: NSViewController?
        
        switch outlineViewSelection.count {
        case 0:
            // No selection.
            viewController = nil
        case 1:
            // A single selection.
            if let node = OutlineViewController.node(from: selection?[0] as Any) {
                if let url = node.url {
                    // The node has a URL.
                    if node.isDirectory {
                        // It is a folder URL.
                        iconViewController.url = url
                        viewController = iconViewController
                    } else {
                        // It is a file URL.
                        fileViewController.url = url
                        viewController = fileViewController
                    }
                } else {
                    // The node doesn't have a URL.
                    if node.isDirectory {
                        // It is a non-URL grouping of pictures.
                        iconViewController.nodeContent = node
                        viewController = iconViewController
                    } else {
                        // It is a non-URL image document, so load its image.
                        if let loadedImage = NSImage(named: node.title) {
                            imageViewController.fileImageView?.image = loadedImage
                        } else {
                            debugPrint("Failed to load built-in image: \(node.title)")
                        }
                        viewController = imageViewController
                    }
                }
            }
        default:
            // The selection is multiple or more than one.
            viewController = multipleItemsViewController
        }

        return viewController
    }
    
    // MARK: File Promise Drag Handling

    /// The queue for reading and writing file promises.
    lazy var workQueue: OperationQueue = {
        let providerQueue = OperationQueue()
        providerQueue.qualityOfService = .userInitiated
        return providerQueue
    }()
    
}

