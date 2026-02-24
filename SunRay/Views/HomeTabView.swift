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
            .background(.clear)
            .navigationTitle("SunRay")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            isRefreshing = true
                            defer { isRefreshing = false }
                            await appState.refreshEnvironmentalData(showAlertOnFailure: true)
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
                StartExposureScreen(
                    initialSPF: appState.activeSession?.spf ?? appState.settings.defaultSPF,
                    initialClothing: appState.activeSession?.clothing ?? appState.settings.defaultClothing
                )
                .environmentObject(appState)
                .presentationBackground(.ultraThinMaterial)
                .presentationCornerRadius(32)
            }
            .refreshable {
                await appState.refreshEnvironmentalData(showAlertOnFailure: true)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(appState.greeting)
                    .font(.title2.bold())
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.yellow, .white],
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
                .symbolEffect(.breathe)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            .linearGradient(
                                colors: [.white.opacity(0.4), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
    }

    private var uvCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Current UV Index")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text(appState.uvIndexString)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(appState.uvColor)
                        .shadow(color: appState.uvColor.opacity(0.5), radius: 16, x: 0, y: 6)
                        .shimmer(duration: 3.0)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.uvAdvisory)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Label("\(appState.cloudCoverString) clouds", systemImage: "cloud.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let burnTime = appState.burnTimeString {
                            Label("~\(burnTime) unprotected burn", systemImage: "flame.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    Spacer()
                }
            }
        }
    }

    private var progressCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Vitamin D Goal")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                // During an active session, include live accumulated IU in the bar.
                if appState.isSessionActive {
                    TimelineView(.periodic(from: .now, by: 30)) { _ in
                        vitaminDBar(currentIU: appState.todaySynthesizedIU + appState.liveSessionIU)
                    }
                } else {
                    vitaminDBar(currentIU: appState.todaySynthesizedIU)
                }

                if let recommendation = appState.exposureRecommendation {
                    HStack(spacing: 8) {
                        Image(systemName: "sun.min.fill")
                            .foregroundStyle(.yellow)
                        Text("~\(recommendation.durationMinutes) min recommended now")
                            .font(.footnote)
                        Spacer()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func vitaminDBar(currentIU: Double) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(Int(currentIU)) IU")
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
                                colors: [.yellow, .white],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * min(currentIU / appState.settings.dailyGoalIU, 1.0),
                            height: 12
                        )
                        .shadow(color: .yellow.opacity(0.6), radius: 6, x: 0, y: 3)
                        .shimmer(duration: 2.5, bounce: true)
                }
            }
            .frame(height: 12)
        }
    }

    private var sessionControls: some View {
        GlassCard {
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
                                .symbolEffect(.pulse)
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
                        Text(session.clothing.shortName)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    // Live elapsed time and accumulated IU — refreshes every 30 seconds.
                    TimelineView(.periodic(from: session.start, by: 30)) { _ in
                        let elapsed = Int(Date().timeIntervalSince(session.start) / 60)
                        let liveIU = Int(appState.liveSessionIU)
                        HStack(spacing: 8) {
                            Label("\(elapsed) min elapsed", systemImage: "timer")
                            Spacer()
                            Text("~\(liveIU) IU so far")
                                .fontWeight(.semibold)
                        }
                        .font(.caption)
                        .foregroundStyle(.green)
                    }
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
                        .tint(.yellow)
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
                        .tint(.yellow)
                        .controlSize(.large)
                        .shimmer(duration: 4.0)
                    }
                }
            }
        }
    }

    private var footerTips: some View {
        VStack(spacing: 8) {
            Text("Estimates only. Consult a healthcare professional for personalized advice.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            if !appState.healthKitAuthorized {
                Label("Health permissions needed to save UV and vitamin D data.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
        }
        .padding()
    }
}

#Preview {
    HomeTabView()
        .environmentObject(AppState.preview)
}
