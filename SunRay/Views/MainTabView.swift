//
//  MainTabView.swift
//  SunRay
//
//  Created with liquid glass aesthetic
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Global Metal shader overlay for liquid glass effect
            SunrayView()
                .allowsHitTesting(false)
                .ignoresSafeArea()
                .opacity(0.15)
                .blendMode(.plusLighter)

            TabView(selection: $selectedTab) {
                HomeTabView()
                    .tabItem {
                        Label("Home", systemImage: "sun.max.fill")
                    }
                    .tag(0)

                HistoryTabView()
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(1)

                SettingsTabView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(2)
            }
            .tint(.orange)
        }
        .task {
            await appState.bootstrap()
        }
        .alert(
            item: Binding(
                get: { appState.activeAlert },
                set: { appState.activeAlert = $0 }
            )
        ) { (alert: AppState.UIAlert) in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState.preview)
}
