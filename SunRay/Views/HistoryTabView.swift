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
    @State private var deleteHapticTrigger = false

    // Sessions bucketed by calendar day, newest day first.
    private var groupedSessions: [(label: String, sessions: [ExposureSession])] {
        let cal       = Calendar.current
        let today     = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        var map: [Date: [ExposureSession]] = [:]
        for session in appState.allSessions {
            map[cal.startOfDay(for: session.start), default: []].append(session)
        }
        return map.keys.sorted(by: >).map { day in
            let label: String
            if day == today        { label = "Today" }
            else if day == yesterday { label = "Yesterday" }
            else { label = day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()) }
            return (label, map[day]!)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if appState.allSessions.isEmpty {
                        emptyStateView
                            .padding()
                    } else {
                        ForEach(groupedSessions, id: \.label) { group in
                            // Day header
                            Text(group.label)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                                .padding(.top, 20)
                                .padding(.bottom, 8)

                            ForEach(group.sessions) { session in
                                sessionCard(session)
                                    .padding(.horizontal)
                                    .padding(.bottom, 12)
                            }
                        }
                    }
                }
                .padding(.bottom)
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
        .sunrayBackground(uvIndex: Float(appState.currentUVIndex ?? 5.0))
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var emptyStateView: some View {
        GlassCard {
            VStack(spacing: 16) {
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.yellow, .white],
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
                        // The day is shown in the section header; show start→end time here.
                        if let end = session.end {
                            Text("\(session.start.formatted(date: .omitted, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))")
                                .font(.headline)
                        } else {
                            Text(session.start.formatted(date: .omitted, time: .shortened))
                                .font(.headline)
                        }
                        Text(session.skinType.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let end = session.end {
                        let totalMin = Int(end.timeIntervalSince(session.start) / 60)
                        let rem = totalMin % 60
                        let durationText = totalMin >= 60
                            ? (rem == 0 ? "\(totalMin / 60)h" : "\(totalMin / 60)h \(rem)m")
                            : "\(totalMin) min"
                        Text(durationText)
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vitamin D")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        // estimatedIU is nil when the app was killed mid-session;
                        // show em-dash rather than a misleading "0 IU".
                        Text(session.estimatedIU.map { "\(Int($0)) IU" } ?? "—")
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
                        Text("Clothing")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(session.clothing.shortName)
                            .font(.body.bold())
                    }

                    Spacer()

                    Button(role: .destructive) {
                        sessionToDelete = session
                        showingDeleteConfirmation = true
                        deleteHapticTrigger.toggle()
                    } label: {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundStyle(.red)
                    }
                    .sensoryFeedback(.warning, trigger: deleteHapticTrigger)
                }
            }
        }
    }
}

#Preview {
    HistoryTabView()
        .environmentObject(AppState.preview)
}
