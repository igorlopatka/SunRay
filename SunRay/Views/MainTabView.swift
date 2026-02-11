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
            // Animated background gradient
            AnimatedMeshGradient(colors: backgroundColors)
                .ignoresSafeArea()

            // Global Metal shader overlay for liquid glass effect
            SunrayView()
                .allowsHitTesting(false)
                .ignoresSafeArea()
                .opacity(0.15)
                .blendMode(.plusLighter)

            // Floating particles effect
            FloatingParticles()
                .ignoresSafeArea()

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

    private var backgroundColors: [Color] {
        switch selectedTab {
        case 0:
            return [
                .orange.opacity(0.15), .yellow.opacity(0.08), .orange.opacity(0.12),
                .yellow.opacity(0.08), .clear, .yellow.opacity(0.08),
                .orange.opacity(0.12), .yellow.opacity(0.08), .orange.opacity(0.15)
            ]
        case 1:
            return [
                .blue.opacity(0.15), .cyan.opacity(0.08), .blue.opacity(0.12),
                .cyan.opacity(0.08), .clear, .cyan.opacity(0.08),
                .blue.opacity(0.12), .cyan.opacity(0.08), .blue.opacity(0.15)
            ]
        case 2:
            return [
                .purple.opacity(0.15), .pink.opacity(0.08), .purple.opacity(0.12),
                .pink.opacity(0.08), .clear, .pink.opacity(0.08),
                .purple.opacity(0.12), .pink.opacity(0.08), .purple.opacity(0.15)
            ]
        default:
            return [.clear, .clear, .clear, .clear, .clear, .clear, .clear, .clear, .clear]
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState.preview)
}
