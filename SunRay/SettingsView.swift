import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    Picker("Skin Type", selection: $appState.settings.skinType) {
                        ForEach(FitzpatrickSkinType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    Stepper("Default SPF \(appState.settings.defaultSPF)", value: $appState.settings.defaultSPF, in: 0...100)
                    HStack {
                        Text("Default Exposed Skin")
                        Spacer()
                        Text("\(Int(appState.settings.defaultExposedPercent))%")
                    }
                    Slider(value: $appState.settings.defaultExposedPercent, in: 0...100, step: 5)
                }

                Section("Goals") {
                    Stepper("Daily Goal \(Int(appState.settings.dailyGoalIU)) IU", value: $appState.settings.dailyGoalIU, in: 200...4000, step: 100)
                }

                Section("About") {
                    Text("Estimates only. This app does not provide medical advice.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        Task { await appState.persistence.saveSettings(appState.settings) }
                        dismiss()
                    }
                }
            }
        }
    }
}
