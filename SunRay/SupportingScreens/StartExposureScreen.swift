import SwiftUI

struct StartExposureScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    @State private var spf: Int
    @State private var exposedPercent: Double

    init() {
        _spf = State(initialValue: 15)
        _exposedPercent = State(initialValue: 25)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Settings") {
                    Stepper("SPF \(spf)", value: $spf, in: 0...100)
                    HStack {
                        Text("Exposed Skin")
                        Spacer()
                        Text("\(Int(exposedPercent))%")
                    }
                    Slider(value: $exposedPercent, in: 0...100, step: 5)
                    Picker("Skin Type", selection: $appState.settings.skinType) {
                        ForEach(FitzpatrickSkinType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                if let uv = appState.currentUVIndex, let elev = appState.solarElevation {
                    let iuPer30 = VitaminDModel.estimateSynthesizedIU(
                        uvIndex: uv,
                        minutes: 30,
                        solarElevation: elev,
                        cloudCover: appState.cloudCover ?? 0,
                        skinType: appState.settings.skinType,
                        spf: spf,
                        exposedPercent: exposedPercent
                    )
                    Section("Estimate") {
                        Text("~\(Int(iuPer30)) IU in 30 min under current conditions.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(appState.isSessionActive ? "Adjust Session" : "Start Session")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(appState.isSessionActive ? "Update" : "Start") {
                        if appState.isSessionActive {
                            appState.updateActiveSession(spf: spf, exposedPercent: exposedPercent)
                        } else {
                            appState.startSession(spf: spf, exposedPercent: exposedPercent)
                        }
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .onAppear {
                spf = appState.isSessionActive ? (appState.activeSession?.spf ?? appState.settings.defaultSPF) : appState.settings.defaultSPF
                exposedPercent = appState.isSessionActive ? (appState.activeSession?.exposedSkinPercent ?? appState.settings.defaultExposedPercent) : appState.settings.defaultExposedPercent
            }
        }
    }
}
