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
                        .blue.opacity(0.1), .cyan.opacity(0.05), .blue.opacity(0.1),
                        .cyan.opacity(0.05), .clear, .cyan.opacity(0.05),
                        .blue.opacity(0.1), .cyan.opacity(0.05), .blue.opacity(0.1)
                    ]
                )
                .ignoresSafeArea()
            }
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
        .padding(40)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .padding(.top, 60)
    }

    private func sessionCard(_ session: ExposureSession) -> some View {
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
                                colors: [.orange, .yellow],
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
    HistoryTabView()
        .environmentObject(AppState.preview)
}
