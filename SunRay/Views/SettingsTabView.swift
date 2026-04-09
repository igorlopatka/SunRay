//
//  SettingsTabView.swift
//  SunRay
//
//  Settings tab with liquid glass aesthetic
//

import SwiftUI

struct SettingsTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileSection
                    goalsSection
                    methodologySection
                    aboutSection
                }
                .padding()
            }
            .background(.clear)
            .navigationTitle("Settings")
            .onChange(of: appState.settings) {
                Task { await appState.saveSettings() }
            }
        }
        .sunrayBackground(opacity: 0.2, uvIndex: Float(appState.currentUVIndex ?? 5.0))
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var profileSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Profile")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 16) {
                    HStack {
                        Text("Skin Type")
                            .font(.body)
                        Spacer()
                        Picker("Skin Type", selection: $appState.settings.skinType) {
                            ForEach(FitzpatrickSkinType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Divider()

                    HStack {
                        Text("Age")
                            .font(.body)
                        Spacer()
                        Stepper("\(appState.settings.age) yrs", value: $appState.settings.age, in: 1...120)
                            .fixedSize()
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Default SPF")
                                .font(.body)
                            Spacer()
                            Text("\(appState.settings.defaultSPF)")
                                .font(.body.bold().monospacedDigit())
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        Slider(value: Binding(
                            get: { Double(appState.settings.defaultSPF) },
                            set: { appState.settings.defaultSPF = Int($0) }
                        ), in: 1...50, step: 1)
                        .tint(.blue)
                    }

                    Divider()

                    HStack {
                        Text("Default Clothing")
                            .font(.body)
                        Spacer()
                        Picker("Default Clothing", selection: $appState.settings.defaultClothing) {
                            ForEach(ClothingLevel.allCases) { level in
                                Text(level.shortName).tag(level)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
    }

    private var goalsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Daily Goals")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Target Vitamin D")
                            .font(.body)
                        Spacer()
                        Text("\(Int(appState.settings.dailyGoalIU)) IU")
                            .font(.body.bold().monospacedDigit())
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    Slider(value: $appState.settings.dailyGoalIU, in: 200...2000, step: 100)
                        .tint(.blue)

                    Text("Recommended: 600-800 IU for most adults")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var methodologySection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Methodology & References")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Synthesis model")
                        .font(.system(.subheadline, design: .serif).bold())

                    Text("IU output is estimated using a Michaelis-Menten UV saturation curve calibrated to produce ~562 IU per 30 min under midday summer conditions (UV 5, skin Type III, SPF 1, 25% exposed skin, clear sky) — consistent with the Holick 2007 reference point. Factors for SPF, cloud cover, skin type, exposed area, and age are applied multiplicatively.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider()

                    Text("Clinical references")
                        .font(.system(.subheadline, design: .serif).bold())

                    ForEach(clinicalReferences, id: \.citation) { ref in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ref.topic)
                                .font(.caption.bold())
                            Text(ref.citation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private struct Reference {
        let topic: String
        let citation: String
    }

    private let clinicalReferences: [Reference] = [
        .init(topic: "Vitamin D synthesis — base calibration",
              citation: "Holick MF. Vitamin D deficiency. N Engl J Med. 2007;357(3):266–281."),
        .init(topic: "UV saturation kinetics",
              citation: "Engelsen O. The relationship between ultraviolet radiation exposure and vitamin D status. Photochem Photobiol Sci. 2010;9(3):369–379."),
        .init(topic: "SPF and UVB attenuation",
              citation: "Matsuoka LY et al. Sunscreens suppress cutaneous vitamin D synthesis. J Clin Endocrinol Metab. 1987;64(6):1165–1168."),
        .init(topic: "Cloud cover and UVB transmission",
              citation: "Calbó J et al. Empirical studies of UV transmission by clouds. J Appl Meteorol Climatol. 2005;44(10):1506–1512."),
        .init(topic: "Age-related decline in synthesis",
              citation: "MacLaughlin J, Holick MF. Aging decreases the capacity of human skin to produce vitamin D3. J Clin Invest. 1985;76(4):1536–1538."),
        .init(topic: "Skin type and synthesis efficiency",
              citation: "Clemens TL et al. Increased skin pigment reduces the capacity of skin to synthesise vitamin D3. Lancet. 1982;1(8263):74–76."),
        .init(topic: "Fitzpatrick type synthesis factors",
              citation: "Chen TC et al. Factors that influence the cutaneous synthesis and dietary sources of vitamin D. Arch Biochem Biophys. 2007;460(2):213–217."),
        .init(topic: "Burn time (MED) by skin type",
              citation: "McKinlay AF, Diffey BL. A reference action spectrum for ultraviolet induced erythema in human skin. CIE Research Note. 1987;6(1):17–22."),
    ]

    private var aboutSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("About")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.pulse)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("SunRay")
                                .font(.title3.bold())
                            Text("Vitamin D Tracking")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Health Integration")
                            .font(.subheadline.bold())
                        if appState.healthKitAuthorized {
                            Label("Connected to Apple Health", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Label("Not connected to Apple Health", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    Divider()

                    Text("SunRay helps you track sun exposure and estimate Vitamin D synthesis based on UV index, skin type, and exposure parameters.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    SettingsTabView()
        .environmentObject(AppState.preview)
}
