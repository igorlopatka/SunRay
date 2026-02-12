//
//  SettingsTabView.swift
//  SunRay
//
//  Settings tab with liquid glass aesthetic
//

import SwiftUI

struct SettingsTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileSection
                    goalsSection
                    aboutSection
                }
                .padding()
            }
            .background(.clear)
            .navigationTitle("Settings")
            .onChange(of: appState.settings) {
                Task { await appState.saveSettings() }
            }
        }
    }

    private var profileSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Profile")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 16) {
                    HStack {
                        Text("Skin Type")
                            .font(.body)
                        Spacer()
                        Picker("Skin Type", selection: $appState.settings.skinType) {
                            ForEach(FitzpatrickSkinType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Default SPF")
                                .font(.body)
                            Spacer()
                            Text("\(appState.settings.defaultSPF)")
                                .font(.body.bold().monospacedDigit())
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        Slider(value: Binding(
                            get: { Double(appState.settings.defaultSPF) },
                            set: { appState.settings.defaultSPF = Int($0) }
                        ), in: 1...50, step: 1)
                        .tint(.blue)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Exposed Skin %")
                                .font(.body)
                            Spacer()
                            Text("\(Int(appState.settings.defaultExposedPercent))%")
                                .font(.body.bold().monospacedDigit())
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        Slider(value: $appState.settings.defaultExposedPercent, in: 5...100, step: 5)
                            .tint(.blue)
                    }
                }
            }
        }
    }

    private var goalsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Daily Goals")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Target Vitamin D")
                            .font(.body)
                        Spacer()
                        Text("\(Int(appState.settings.dailyGoalIU)) IU")
                            .font(.body.bold().monospacedDigit())
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    Slider(value: $appState.settings.dailyGoalIU, in: 200...2000, step: 100)
                        .tint(.blue)

                    Text("Recommended: 600-800 IU for most adults")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var aboutSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("About")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.pulse)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("SunRay")
                                .font(.title3.bold())
                            Text("Vitamin D Tracking")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Health Integration")
                            .font(.subheadline.bold())
                        if appState.healthKitAuthorized {
                            Label("Connected to Apple Health", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Label("Not connected to Apple Health", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    Divider()

                    Text("SunRay helps you track sun exposure and estimate Vitamin D synthesis based on UV index, skin type, and exposure parameters.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    SettingsTabView()
        .environmentObject(AppState.preview)
}
