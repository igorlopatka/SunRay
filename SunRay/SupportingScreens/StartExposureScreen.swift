import SwiftUI

struct StartExposureScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    @State private var spf: Int
    @State private var clothing: ClothingLevel
    @State private var hapticTrigger = false

    init(initialSPF: Int, initialClothing: ClothingLevel) {
        _spf = State(initialValue: max(1, initialSPF))
        _clothing = State(initialValue: initialClothing)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Settings") {
                    Stepper("SPF \(spf)", value: $spf, in: 1...50)

                    Picker("Clothing", selection: $clothing) {
                        ForEach(ClothingLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }

                    Picker("Skin Type", selection: $appState.settings.skinType) {
                        ForEach(FitzpatrickSkinType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                if let uv = appState.currentUVIndex {
                    let iuPer30 = VitaminDModel.estimateSynthesizedIU(
                        uvIndex: uv,
                        minutes: 30,
                        cloudCover: appState.cloudCover ?? 0,
                        skinType: appState.settings.skinType,
                        spf: spf,
                        exposedPercent: clothing.exposedPercent,
                        age: appState.settings.age
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
                            appState.updateActiveSession(spf: spf, clothing: clothing)
                        } else {
                            appState.startSession(spf: spf, clothing: clothing)
                        }
                        hapticTrigger.toggle()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .sensoryFeedback(.success, trigger: hapticTrigger)
                }
            }
        }
    }
}
