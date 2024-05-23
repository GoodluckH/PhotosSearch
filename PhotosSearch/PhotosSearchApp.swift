//
//  PhotosSearchApp.swift
//  PhotosSearch
//
//  Created by Xipu Li on 5/16/24.
//

import SwiftUI

@main
struct PhotosSearchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .defaultSize(width: 1200, height: 675)
    }
}
