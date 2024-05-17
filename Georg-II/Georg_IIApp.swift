//
//  Georg_IIApp.swift
//  Georg-II
//
//  Created by Michael Rockhold on 5/15/24.
//

import SwiftUI

@main
struct Georg_IIApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: Georg_IIDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
