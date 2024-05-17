/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 The primary view controller that contains the NSOutlineView.
 */

import Cocoa
import Combine
import UniformTypeIdentifiers // for UTType

class OutlineViewController: NSViewController,
                             NSTextFieldDelegate, // To respond to the text field's edit sending.
                             NSUserInterfaceValidations { // To enable/disable menu items for the outline view.

    // MARK: Outlets

    @IBOutlet weak var outlineView: OutlineView!

    // We observe the tree controller's selection changing.
    var selectionChangedCancellable: Cancellable?

    override var representedObject: Any? {
        didSet {
            selectionChangedCancellable?.cancel()
            if let tc = representedObject as? NSTreeController {
                outlineViewModel = OutlineViewModel(treeController: tc)
                listen(to: tc)
            } else {
                outlineViewModel = nil
            }
        }
    }

    func listen(to treeController: NSTreeController) {
        // Listen to the treeController's selection change so you inform clients to react to selection changes.
        selectionChangedCancellable = treeController.publisher(for: \.selectedNodes)
            .sink() { [self] selectedNodes in
                print("OUTLINE SELECTION \(selectedNodes)")
                // Save the outline selection state for later when the app relaunches.
                self.invalidateRestorableState()
            }
    }


    var outlineViewModel: OutlineViewModel? = nil {
        // Update the view, if already loaded.
        didSet {
            guard let ovm = outlineViewModel, let ov = outlineView else {
                // TODO: do we need to 'unbind'  and 'unsetup'?
                return
            }

            ov.bind(.content,
                    to: ovm.treeController,
                    withKeyPath: "arrangedObjects",
                    options:[.raisesForNotApplicableKeys: true])

            ov.bind(.selectionIndexPaths,
                    to: ovm.treeController,
                    withKeyPath: "selectionIndexPaths",
                    options:[.raisesForNotApplicableKeys: true])
        }
    }

    @IBOutlet private weak var placeHolderView: NSView!

    var rowToAdd = -1 // The addition of a flagged row (for later renaming).

    // The directory for accepting promised files.
    lazy var promiseDestinationURL: URL = {
        let promiseDestinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Drops")
        try? FileManager.default.createDirectory(at: promiseDestinationURL, withIntermediateDirectories: true, attributes: nil)
        return promiseDestinationURL
    }()

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
    }

    override func viewWillAppear() {
        /** Disclose the two root outline groups (Places and Pictures) at first launch.
         With all subsequent launches, the autosave disclosure states determine these disclosure states.
         */
        let defaults = UserDefaults.standard
        let initialDisclosure = defaults.string(forKey: "initialDisclosure")
        if initialDisclosure == nil {
            guard let tc = self.outlineViewModel?.treeController else { return }
            if !(tc.arrangedObjects.children?.isEmpty ?? true) {
                outlineView.expandItem(tc.arrangedObjects.children![0])
                outlineView.expandItem(tc.arrangedObjects.children![1])
            }
            defaults.set("initialDisclosure", forKey: "initialDisclosure")
        }

        if let vm = outlineViewModel {
//            vm.treeController.fetchPredicate = NSPredicate(format: "parent == %@", NSNull())
            vm.treeController.fetch(self)
        }
        outlineView.reloadData()
    }

    deinit {
        selectionChangedCancellable?.cancel()
    }

    // MARK: Removal and Addition

    private func removalConfirmAlert(_ itemsToRemove: [ModelObject]) -> NSAlert {
        let alert = NSAlert()

        var messageStr: String
        if itemsToRemove.count > 1 {
            // Remove multiple items.
            alert.messageText = NSLocalizedString("remove multiple string", comment: "")
        } else {
            // Remove the single item.
            messageStr = NSLocalizedString("remove confirm string", comment: "")
            alert.messageText = String(format: messageStr, itemsToRemove[0].title ?? "<no title>")
        }

        alert.addButton(withTitle: NSLocalizedString("ok button title", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("cancel button title", comment: ""))

        return alert
    }

    // The system calls these from handleContextualMenu() or the remove button.
    // Remove the currently selected items.

    func removeSelectedItems() {
        remove(items: nil)
    }

    func remove(item: ModelObject) {
        remove(items: [item])
    }

    func remove(items itemsToRemove: [ModelObject]? = nil) {
        Task {
            await self.outlineViewModel?.remove(items: itemsToRemove) { itemsToRemove in
                let confirmAlert = removalConfirmAlert(itemsToRemove)
                let response = await confirmAlert.beginSheetModal(for: view.window!)
                return response == NSApplication.ModalResponse.alertFirstButtonReturn
            }
        }
    }

    /// - Tag: Delete
    // The user chose the Delete menu item or pressed the Delete key.
    @IBAction func delete(_ sender: AnyObject) {
        removeSelectedItems()
    }

    // The system calls this from handleContextualMenu() or the add picture button.
    func addFeature(at item: ModelObject) {
        // Present an open panel to choose a picture to display in the outline view.
        let openPanel = NSOpenPanel()

        // Find a picture to add.
        let locationTitle = item.title ?? "<no title>"
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
            guard response == NSApplication.ModalResponse.OK else { return }

            // Get the indexPath of the folder you're adding to.
            guard let itemNodeIndexPath = self.outlineViewModel?.treeController.indexPathOfObject(anObject: item) else { return }

            // You're inserting a new picture at the item node index path.
            let indexPathToInsert = itemNodeIndexPath.appending(IndexPath(index: 0))

            // Create a ModelObject of the type appropriate to where we're inserting it
            fatalError("TODO: unimplemented feature")
        }
    }

    // MARK: Notification handlers

    // A notification that the WindowViewController class sends to add a generic folder to the current selection.
    @objc
    private func addFolder(_ notif: Notification) {
        // Add the folder with the "untitled" title.
        let selectedRow = outlineView.selectedRow
        if let folderToAddNode = self.outlineView.item(atRow: selectedRow) as? NSTreeNode {
            self.addFolder(at: folderToAddNode)
        }
        // Flag the row you're adding (for later renaming).
        rowToAdd = outlineView.selectedRow
    }

    // A notification that the WindowViewController class sends to add a picture to the selected folder node.
    @objc
    private func addFeature(_ notif: Notification) {
        let selectedRow = outlineView.selectedRow

        if let item = self.outlineView.item(atRow: selectedRow) as? NSTreeNode,
           let addToNode = OutlineViewModel.modelObject(from: item) {
            addFeature(at: addToNode)
        }
    }

    // A notification that the WindowViewController remove button sends to remove a selected item from the outline view.
    @objc
    private func removeItem(_ notif: Notification) {
        removeSelectedItems()
    }

    // The system calls this from handleContextualMenu() or the add group button.
    func addFolder(at item: NSTreeNode) {
        if let rowItemNode = self.outlineViewModel?.addFolder(at: item) {
            // Flag the row you're adding (for later renaming).
            rowToAdd = outlineView.row(forItem: item) + (rowItemNode.kidArray?.count ?? 0)
        }
    }

    // MARK: NSTextFieldDelegate

    // For a text field in each outline view item, the user commits the edit operation.
    func controlTextDidEndEditing(_ obj: Notification) {
        // Commit the edit by applying the text field's text to the current node.
        guard let item = outlineView.item(atRow: outlineView.selectedRow) as? NSTreeNode,
              let node = OutlineViewModel.modelObject(from: item) else { return }

        if let textField = obj.object as? NSTextField {
            node.title = textField.stringValue
        }
    }

    // MARK: NSValidatedUserInterfaceItem

    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(delete(_:)) {
            return self.outlineViewModel?.treeController.selectedObjects.isEmpty ?? true
        }
        return true
    }

    // MARK: File Promise Drag Handling

    /// The queue for reading and writing file promises.
    lazy var workQueue: OperationQueue = {
        let providerQueue = OperationQueue()
        providerQueue.qualityOfService = .userInitiated
        return providerQueue
    }()
}

