//
//  UVMapView.swift
//  SunRay
//
//  UV index map — shows the user's current location with a UV-intensity overlay
//  and an info panel. UV index is uniform at city scale (it's determined by sun
//  angle, ozone, and atmospheric path length, not terrain), so the coloured
//  radial gradient represents the *intensity* of UV at the user's location
//  rather than spatial variation.
//

import SwiftUI
import MapKit
import CoreLocation

struct UVMapView: View {
    @EnvironmentObject private var appState: AppState

    // Keep camera centred on user; if no location yet, fall back to automatic.
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer

            // Floating info panel at the bottom
            infoPanel
                .padding(.horizontal)
                .padding(.bottom, 100) // clear the tab bar
        }
        .navigationTitle("UV Map")
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            // Show the system blue-dot for user location
            UserAnnotation()

            if let coord = userCoordinate {
                // Soft radial "UV intensity" ring — colour-coded by UV level.
                MapCircle(center: coord, radius: uvOverlayRadius)
                    .foregroundStyle(appState.uvColor.opacity(0.10))
                    .stroke(appState.uvColor.opacity(0.45), lineWidth: 2)

                // UV index callout bubble above the user
                Annotation("UV", coordinate: offsetCoord(coord, byMeters: uvOverlayRadius * 0.6)) {
                    uvBubble
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }

    // MARK: - UV bubble annotation

    private var uvBubble: some View {
        VStack(spacing: 2) {
            Text(appState.uvIndexString)
                .font(.system(size: 20, weight: .bold, design: .serif).monospacedDigit())
                .foregroundStyle(appState.uvColor)
            Text(uvLevelLabel)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(appState.uvColor.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(appState.uvColor.opacity(0.4), lineWidth: 1)
        }
        .shadow(color: appState.uvColor.opacity(0.3), radius: 8, x: 0, y: 4)
        // VoiceOver: the annotation duplicates info already in the panel below; hide it.
        .accessibilityHidden(true)
    }

    // MARK: - Info panel

    private var infoPanel: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("UV Index")
                            .font(.system(.caption, design: .serif))
                            .foregroundStyle(.secondary)
                        Text(appState.uvIndexString)
                            .font(.system(size: 36, weight: .bold, design: .serif).monospacedDigit())
                            .foregroundStyle(appState.uvColor)
                            .accessibilityLabel("UV Index \(appState.uvIndexString), \(uvLevelLabel)")
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        if let burnTime = appState.burnTimeString {
                            Label("~\(burnTime) burn (no SPF)", systemImage: "flame.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        Label("\(appState.cloudCoverString) cloud cover", systemImage: "cloud.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(appState.uvAdvisory)
                    .font(.system(.footnote, design: .serif))
                    .foregroundStyle(.primary)

                if let recommendation = appState.exposureRecommendation {
                    Divider()
                    Label("~\(recommendation.durationMinutes) min recommended at this UV", systemImage: "sun.min.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }

                Text(appState.locationSummary)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Helpers

    private var userCoordinate: CLLocationCoordinate2D? {
        appState.locationService.location?.coordinate
    }

    /// Visual radius of the UV overlay ring — larger for more intense UV.
    private var uvOverlayRadius: CLLocationDistance {
        guard let uv = appState.currentUVIndex else { return 800 }
        switch uv {
        case ..<3:  return 700
        case 3..<6: return 1_200
        case 6..<8: return 2_000
        case 8..<11: return 3_000
        default:    return 4_500
        }
    }

    private var uvLevelLabel: String {
        guard let uv = appState.currentUVIndex else { return "—" }
        switch uv {
        case ..<3:  return "Low"
        case 3..<6: return "Moderate"
        case 6..<8: return "High"
        case 8..<11: return "Very High"
        default:    return "Extreme"
        }
    }

    /// Returns a coordinate shifted north of `base` by `meters`.
    private func offsetCoord(_ base: CLLocationCoordinate2D, byMeters meters: Double) -> CLLocationCoordinate2D {
        let earthRadius = 6_371_000.0
        let latDelta = (meters / earthRadius) * (180 / .pi)
        return CLLocationCoordinate2D(latitude: base.latitude + latDelta, longitude: base.longitude)
    }
}

#Preview {
    NavigationStack {
        UVMapView()
            .environmentObject(AppState.preview)
    }
}
