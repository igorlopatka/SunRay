//
//  HistoryTabView.swift
//  SunRay
//
//  History tab with liquid glass aesthetic
//

import SwiftUI

struct HistoryTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingDeleteConfirmation = false
    @State private var sessionToDelete: ExposureSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if appState.allSessions.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(appState.allSessions) { session in
                            sessionCard(session)
                        }
                    }
                }
                .padding()
            }
            .background(.clear)
            .navigationTitle("History")
            .confirmationDialog(
                "Delete Session",
                isPresented: $showingDeleteConfirmation,
                presenting: sessionToDelete
            ) { session in
                Button("Delete", role: .destructive) {
                    appState.deleteSession(session)
                }
            } message: { _ in
                Text("Are you sure you want to delete this session?")
            }
        }
    }

    private var emptyStateView: some View {
        GlassCard {
            VStack(spacing: 16) {
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolEffect(.bounce)

                Text("No Sessions Yet")
                    .font(.title2.bold())

                Text("Start tracking your sun exposure to see your history here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 60)
    }

    private func sessionCard(_ session: ExposureSession) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.start.formatted(date: .abbreviated, time: .omitted))
                            .font(.headline)
                        Text(session.start.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let end = session.end {
                        let duration = end.timeIntervalSince(session.start)
                        Text("\(Int(duration / 60)) min")
                            .font(.title3.bold().monospacedDigit())
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }

                Divider()

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vitamin D")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(session.estimatedIU)) IU")
                            .font(.body.bold().monospacedDigit())
                    }

                    Divider()
                        .frame(height: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("SPF")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(session.spf)")
                            .font(.body.bold().monospacedDigit())
                    }

                    Divider()
                        .frame(height: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Skin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(session.exposedSkinPercent))%")
                            .font(.body.bold().monospacedDigit())
                    }

                    Spacer()

                    Button(role: .destructive) {
                        sessionToDelete = session
                        showingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }
}

#Preview {
    HistoryTabView()
        .environmentObject(AppState.preview)
}
