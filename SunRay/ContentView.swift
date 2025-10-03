//
//  ContentView.swift
//  SunRay
//
//  Created by Igor Łopatka on 03/10/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var showingSessionSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                header

                uvCard

                progressCard

                sessionControls

                Spacer(minLength: 12)

                footerTips
            }
            .padding()
            .navigationTitle("SunRay")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel("History")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView()
                    .environmentObject(appState)
            }
            .task {
                await appState.bootstrap()
            }
            .alert(item: $appState.activeAlert) { (alert: AppState.UIAlert) in
                Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello, \(appState.displayName)")
                    .font(.title3).bold()
                Text(appState.locationSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "sun.max.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 36))
        }
    }

    private var uvCard: some View {
        GroupBox {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Current UV Index")
                        .font(.headline)
                    Text(appState.uvIndexString)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(appState.uvColor)
                    Text(appState.uvAdvisory)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Label("\(appState.cloudCoverString) clouds", systemImage: "cloud.fill")
                        .foregroundStyle(.secondary)
                    Label(appState.solarElevationString, systemImage: "sun.horizon.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var progressCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Vitamin D Goal")
                    .font(.headline)

                HStack {
                    ProgressView(value: appState.todaySynthesizedIU, total: appState.settings.dailyGoalIU) {
                        Text("\(Int(appState.todaySynthesizedIU)) / \(Int(appState.settings.dailyGoalIU)) IU")
                            .font(.body.monospacedDigit())
                    }
                    .progressViewStyle(.linear)
                }

                if let recommendation = appState.exposureRecommendation {
                    HStack(spacing: 8) {
                        Image(systemName: "sun.min.fill")
                        Text("Recommended: \(recommendation.durationMinutes) min \(recommendation.windowText)")
                        Spacer()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var sessionControls: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Sun Session")
                        .font(.headline)
                    Spacer()
                    if appState.isSessionActive {
                        Label("Active", systemImage: "timer")
                            .foregroundStyle(.green)
                    } else {
                        Label("Idle", systemImage: "pause.circle")
                            .foregroundStyle(.secondary)
                    }
                }

                if let session = appState.activeSession {
                    HStack {
                        Text("Started: \(session.start.formatted(date: .omitted, time: .shortened))")
                        Spacer()
                        Text("SPF \(session.spf)")
                        Divider()
                        Text("\(Int(session.exposedSkinPercent))% skin")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                } else {
                    Text("Track a session to estimate synthesized Vitamin D from sun exposure.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    if appState.isSessionActive {
                        Button(role: .destructive) {
                            Task { await appState.stopSessionAndSave() }
                        } label: {
                            Label("Stop", systemImage: "stop.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)

                        Spacer()

                        Button {
                            showingSessionSheet = true
                        } label: {
                            Label("Adjust", systemImage: "slider.horizontal.3")
                        }
                    } else {
                        Button {
                            showingSessionSheet = true
                        } label: {
                            Label("Start Session", systemImage: "play.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSessionSheet) {
            StartExposureView()
                .environmentObject(appState)
        }
    }

    private var footerTips: some View {
        VStack(spacing: 6) {
            Text("Estimates only. Consult a healthcare professional for personalized advice.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if !appState.healthKitAuthorized {
                Label("Health permissions needed to save UV exposure.", systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.preview)
}
