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
            .background {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        .init(0, 0), .init(0.5, 0), .init(1, 0),
                        .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
                        .init(0, 1), .init(0.5, 1), .init(1, 1)
                    ],
                    colors: [
                        .purple.opacity(0.1), .pink.opacity(0.05), .purple.opacity(0.1),
                        .pink.opacity(0.05), .clear, .pink.opacity(0.05),
                        .purple.opacity(0.1), .pink.opacity(0.05), .purple.opacity(0.1)
                    ]
                )
                .ignoresSafeArea()
            }
            .navigationTitle("Settings")
        }
    }

    private var profileSection: some View {
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
                        Text("I").tag(1)
                        Text("II").tag(2)
                        Text("III").tag(3)
                        Text("IV").tag(4)
                        Text("V").tag(5)
                        Text("VI").tag(6)
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
                            .foregroundStyle(.orange)
                    }
                    Slider(value: Binding(
                        get: { Double(appState.settings.defaultSPF) },
                        set: { appState.settings.defaultSPF = Int($0) }
                    ), in: 0...50, step: 5)
                    .tint(.orange)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Exposed Skin %")
                            .font(.body)
                        Spacer()
                        Text("\(Int(appState.settings.defaultExposedPercent))%")
                            .font(.body.bold().monospacedDigit())
                            .foregroundStyle(.orange)
                    }
                    Slider(value: $appState.settings.defaultExposedPercent, in: 5...100, step: 5)
                        .tint(.orange)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThickMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            .linearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }

    private var goalsSection: some View {
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
                                colors: [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                Slider(value: $appState.settings.dailyGoalIU, in: 200...2000, step: 100)
                    .tint(.orange)

                Text("Recommended: 600-800 IU for most adults")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThickMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            .linearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }

    private var aboutSection: some View {
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
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

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
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThickMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            .linearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

#Preview {
    SettingsTabView()
        .environmentObject(AppState.preview)
}
