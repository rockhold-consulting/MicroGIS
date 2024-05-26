//
//  HostController.swift
//  Georg
//
//  Created by Michael Rockhold on 5/16/24.
//

import Foundation
import SwiftUI
import CoreData

class HostingController<Content: View>: NSHostingController<Content> {

    @MainActor
    init(rootView: Content, frame: NSRect) {
        super.init(rootView: rootView)
        self.view.frame = frame
    }
    
    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
