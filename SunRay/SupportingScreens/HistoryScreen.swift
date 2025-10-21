import SwiftUI

struct HistoryScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                if appState.history.isEmpty {
                    ContentUnavailableView("No Sessions Yet", systemImage: "sun.min", description: Text("Start a sun session to see your history here."))
                } else {
                    ForEach(appState.history) { session in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(session.start, style: .date)
                                Spacer()
                                Text("\(session.durationMinutes) min")
                            }
                            .font(.subheadline)

                            HStack(spacing: 12) {
                                Label("SPF \(session.spf)", systemImage: "shield.lefthalf.filled")
                                Label("\(Int(session.exposedSkinPercent))%", systemImage: "figure.arms.open")
                                if let iu = session.estimatedIU {
                                    Label("\(Int(iu)) IU", systemImage: "capsule")
                                }
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
