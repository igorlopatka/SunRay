//
//  HomeTabView.swift
//  SunRay
//
//  Home tab with liquid glass aesthetic
//

import SwiftUI

struct HomeTabView: View {

    @EnvironmentObject private var appState: AppState
    @State private var showingSessionSheet = false
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    uvCard

                    progressCard

                    sessionControls

                    Spacer(minLength: 12)

                    footerTips
                }
                .padding()
            }
            .background {
                // Liquid glass background with mesh gradient
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        .init(0, 0), .init(0.5, 0), .init(1, 0),
                        .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
                        .init(0, 1), .init(0.5, 1), .init(1, 1)
                    ],
                    colors: [
                        .orange.opacity(0.1), .yellow.opacity(0.05), .orange.opacity(0.1),
                        .yellow.opacity(0.05), .clear, .yellow.opacity(0.05),
                        .orange.opacity(0.1), .yellow.opacity(0.05), .orange.opacity(0.1)
                    ]
                )
                .ignoresSafeArea()
            }
            .navigationTitle("SunRay")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            isRefreshing = true
                            defer { isRefreshing = false }
                            await appState.refreshEnvironmentalData()
                        }
                    } label: {
                        if isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .accessibilityLabel("Refresh")
                }
            }
            .sheet(isPresented: $showingSessionSheet) {
                StartExposureScreen()
                    .environmentObject(appState)
                    .presentationBackground(.ultraThinMaterial)
                    .presentationCornerRadius(32)
            }
            .refreshable {
                await appState.refreshEnvironmentalData()
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello, \(appState.displayName)")
                    .font(.title2.bold())
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text(appState.locationSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "sun.max.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 44))
                .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }

    private var uvCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current UV Index")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(appState.uvIndexString)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(appState.uvColor)
                    .shadow(color: appState.uvColor.opacity(0.3), radius: 12, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.uvAdvisory)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Label("\(appState.cloudCoverString) clouds", systemImage: "cloud.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
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

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vitamin D Goal")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                HStack {
                    Text("\(Int(appState.todaySynthesizedIU)) IU")
                        .font(.title2.bold().monospacedDigit())
                    Spacer()
                    Text("\(Int(appState.settings.dailyGoalIU)) IU")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.quaternary)
                            .frame(height: 12)

                        Capsule()
                            .fill(
                                .linearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geo.size.width * min(appState.todaySynthesizedIU / appState.settings.dailyGoalIU, 1.0),
                                height: 12
                            )
                            .shadow(color: .orange.opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(height: 12)
            }

            if let recommendation = appState.exposureRecommendation {
                HStack(spacing: 8) {
                    Image(systemName: "sun.min.fill")
                        .foregroundStyle(.orange)
                    Text("Recommended: \(recommendation.durationMinutes) min \(recommendation.windowText)")
                        .font(.footnote)
                    Spacer()
                }
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

    private var sessionControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Sun Session")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                if appState.isSessionActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                            .shadow(color: .green, radius: 4)
                        Text("Active")
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.secondary)
                            .frame(width: 8, height: 8)
                        Text("Idle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let session = appState.activeSession {
                HStack(spacing: 12) {
                    Label(session.start.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                    Divider()
                        .frame(height: 16)
                    Text("SPF \(session.spf)")
                    Divider()
                        .frame(height: 16)
                    Text("\(Int(session.exposedSkinPercent))% skin")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                Text("Track a session to estimate synthesized Vitamin D from sun exposure.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                if appState.isSessionActive {
                    Button(role: .destructive) {
                        Task { await appState.stopSessionAndSave() }
                    } label: {
                        Label("Stop", systemImage: "stop.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)

                    Button {
                        showingSessionSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.headline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .controlSize(.large)
                } else {
                    Button {
                        showingSessionSheet = true
                    } label: {
                        Label("Start Session", systemImage: "play.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.large)
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

    private var footerTips: some View {
        VStack(spacing: 8) {
            Text("Estimates only. Consult a healthcare professional for personalized advice.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            if !appState.healthKitAuthorized {
                Label("Health permissions needed to save UV exposure.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
    }
}

#Preview {
    HomeTabView()
        .environmentObject(AppState.preview)
}
