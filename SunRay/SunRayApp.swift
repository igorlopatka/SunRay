//
//  SunRayApp.swift
//  SunRay
//
//  Created by Igor Łopatka on 03/10/2025.
//

import SwiftUI

@main
struct SunRayApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
        }
    }
}
