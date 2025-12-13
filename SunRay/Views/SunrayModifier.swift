import SwiftUI

struct SunrayModifier: ViewModifier {
    var opacity: Double = 0.6
    func body(content: Content) -> some View {
        ZStack {
            content
            SunrayView()
                .blendMode(.screen)
                .allowsHitTesting(false)
                .opacity(opacity)
                .ignoresSafeArea()
        }
    }
}

extension View {
    func sunrays(opacity: Double = 0.6) -> some View {
        modifier(SunrayModifier(opacity: opacity))
    }
}
