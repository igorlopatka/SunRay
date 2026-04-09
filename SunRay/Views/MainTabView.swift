//
//  MainTabView.swift
//  SunRay
//
//  Created with liquid glass aesthetic
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            // Metal sun shader is the background — sky fill + god rays cover the whole screen.
            SunrayView(uvIndex: Float(appState.currentUVIndex ?? 5.0))
                .allowsHitTesting(false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            // Floating particles effect
            FloatingParticles()
                .ignoresSafeArea()

            TabView {
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

                NavigationStack {
                    UVMapView()
                }
                .tabItem {
                    Label("UV Map", systemImage: "map.fill")
                }
                .tag(2)

                SettingsTabView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .tint(.yellow)
            .toolbarBackground(.hidden, for: .tabBar)
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
