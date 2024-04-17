/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 The view controller that manages the split-view interface.
 */

import Cocoa
import Combine

class SplitViewController: NSSplitViewController {

    private var verticalConstraints: [NSLayoutConstraint] = []
    private var horizontalConstraints: [NSLayoutConstraint] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        /** Note: Keep the left split-view item from growing as the window grows by setting its hugging priority to 200,
         and the right split view item to 199. The view with the lowest priority is the first to take on additional
         width if the split-view grows or shrinks.
         */

        // This preserves the split-view divider position.
        splitView.autosaveName = "SplitViewAutoSave"
    }

    // MARK: Sub View Controller Management

    private var outlineViewController: NSViewController {
        return splitViewItems[0].viewController
    }
    private var mapViewController: NSViewController {
        return splitViewItems[1].viewController
    }
    private var inspectorViewController: NSViewController {
        return splitViewItems[2].viewController
    }
}
