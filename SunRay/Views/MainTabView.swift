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
            // Animated background gradient — cross-fades between tab palettes and UV severity bands.
            AnimatedMeshGradient(colors: backgroundColors)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.45), value: selectedTab)
                .animation(.easeInOut(duration: 0.8), value: uvBand)

            // Global Metal shader overlay — brightness and tint track live UV level.
            SunrayView(uvIndex: Float(appState.currentUVIndex ?? 5.0))
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

    // 0 = low UV (0–2), 1 = moderate (3–5), 2 = high (6–7), 3 = very high/extreme (8+)
    private var uvBand: Int {
        let uv = appState.currentUVIndex ?? 3.0
        if uv >= 8 { return 3 }
        if uv >= 6 { return 2 }
        if uv >= 3 { return 1 }
        return 0
    }

    private var backgroundColors: [Color] {
        switch selectedTab {
        case 0:
            // Home tab palette shifts with UV severity so the ambient colour
            // gives a passive, at-a-glance cue about current conditions.
            switch uvBand {
            case 3: // Very High / Extreme — red-orange
                return [
                    .orange.opacity(0.14), .red.opacity(0.07), .orange.opacity(0.11),
                    .red.opacity(0.07), .clear, .red.opacity(0.07),
                    .orange.opacity(0.11), .red.opacity(0.07), .orange.opacity(0.14)
                ]
            case 2: // High — warm orange-amber
                return [
                    .orange.opacity(0.12), .yellow.opacity(0.06), .orange.opacity(0.10),
                    .yellow.opacity(0.06), .clear, .yellow.opacity(0.06),
                    .orange.opacity(0.10), .yellow.opacity(0.06), .orange.opacity(0.12)
                ]
            case 1: // Moderate — warm yellow (original palette)
                return [
                    .yellow.opacity(0.12), .yellow.opacity(0.06), .yellow.opacity(0.10),
                    .yellow.opacity(0.06), .clear, .yellow.opacity(0.06),
                    .yellow.opacity(0.10), .yellow.opacity(0.06), .yellow.opacity(0.12)
                ]
            default: // Low — cool cyan-white
                return [
                    .cyan.opacity(0.10), .blue.opacity(0.05), .cyan.opacity(0.08),
                    .blue.opacity(0.05), .clear, .blue.opacity(0.05),
                    .cyan.opacity(0.08), .blue.opacity(0.05), .cyan.opacity(0.10)
                ]
            }
        case 1:
            return [
                .blue.opacity(0.15), .cyan.opacity(0.08), .blue.opacity(0.12),
                .cyan.opacity(0.08), .clear, .cyan.opacity(0.08),
                .blue.opacity(0.12), .cyan.opacity(0.08), .blue.opacity(0.15)
            ]
        case 2: // UV Map — green/teal tones to echo earth/environment
            return [
                .green.opacity(0.10), .teal.opacity(0.06), .green.opacity(0.08),
                .teal.opacity(0.06), .clear, .teal.opacity(0.06),
                .green.opacity(0.08), .teal.opacity(0.06), .green.opacity(0.10)
            ]
        case 3: // Settings
            return [
                .blue.opacity(0.12), .cyan.opacity(0.06), .blue.opacity(0.10),
                .cyan.opacity(0.06), .clear, .cyan.opacity(0.06),
                .blue.opacity(0.10), .cyan.opacity(0.06), .blue.opacity(0.12)
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
