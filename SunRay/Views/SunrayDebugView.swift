import SwiftUI

struct SunrayDebugView: View {
    @ObservedObject private var s = SunrayDebugSettings.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sunray Debug").font(.headline)
            HStack {
                Text("Intensity").frame(width: 80, alignment: .leading)
                Slider(value: Binding(get: { Double(s.intensity) }, set: { s.intensity = Float($0) }), in: 0...3)
                Text(String(format: "%.2f", s.intensity)).frame(width: 50)
            }
            HStack {
                Text("Beam Width").frame(width: 80, alignment: .leading)
                Slider(value: Binding(get: { Double(s.beamWidth) }, set: { s.beamWidth = Float($0) }), in: 0...1)
                Text(String(format: "%.2f", s.beamWidth)).frame(width: 50)
            }
            HStack {
                Text("Beams").frame(width: 80, alignment: .leading)
                Slider(value: Binding(get: { Double(s.beamCount) }, set: { s.beamCount = Float($0) }), in: 3...48, step: 1)
                Text(String(format: "%.0f", s.beamCount)).frame(width: 50)
            }
            HStack {
                Text("Hue").frame(width: 80, alignment: .leading)
                Slider(value: Binding(get: { Double(s.hue) }, set: { s.hue = Float($0) }), in: 0...1)
                Color(hue: Double(s.hue), saturation: 0.8, brightness: 1.0)
                    .frame(width: 30, height: 20)
                    .cornerRadius(4)
            }
        }
        .padding(12)
        .background(VisualEffectBlur(blurStyle: .systemThinMaterial))
        .cornerRadius(10)
        .padding()
    }
}

#if DEBUG
struct SunrayDebugView_Previews: PreviewProvider {
    static var previews: some View {
        SunrayDebugView()
            .previewLayout(.sizeThatFits)
    }
}
#endif

// Minimal blur helper for consistent iOS/macOS look
import SwiftUI
// Cross-platform blur helper
#if canImport(UIKit)
import UIKit
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style = .systemThinMaterial
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView(effect: UIBlurEffect(style: blurStyle)) }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
#elseif canImport(AppKit)
import AppKit
struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.blendingMode = .behindWindow
        v.material = .sidebar
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
#else
struct VisualEffectBlur: View { var body: some View { Color(.systemBackground) } }
#endif
