import SwiftUI

struct SunrayModifier: ViewModifier {
    var opacity: Double = 0.6
    var uvIndex: Float = 5.0
    func body(content: Content) -> some View {
        ZStack {
            content
            SunrayView(uvIndex: uvIndex)
                .blendMode(.screen)
                .allowsHitTesting(false)
                .opacity(opacity)
                .ignoresSafeArea()
#if DEBUG
            // Debug toggle — only visible in development builds, stripped from release.
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Button(action: { SunrayDebugSettings.shared.isVisible.toggle() }) {
                            Text("☀︎")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.35))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        if SunrayDebugSettings.shared.isVisible {
                            SunrayDebugView()
                                .frame(maxWidth: 340)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding()
                }
                Spacer()
            }
            .allowsHitTesting(true)
#endif
        }
    }
}

struct SunrayBackgroundModifier: ViewModifier {
    var uvIndex: Float = 5.0

    func body(content: Content) -> some View {
        ZStack {
            SunrayView(uvIndex: uvIndex)
                .allowsHitTesting(false)
                .ignoresSafeArea()

            content
        }
    }
}

extension View {
    func sunrays(opacity: Double = 0.6, uvIndex: Float = 5.0) -> some View {
        modifier(SunrayModifier(opacity: opacity, uvIndex: uvIndex))
    }

    func sunrayBackground(uvIndex: Float = 5.0) -> some View {
        modifier(SunrayBackgroundModifier(uvIndex: uvIndex))
    }
}
