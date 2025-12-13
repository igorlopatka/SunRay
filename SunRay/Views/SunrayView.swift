import SwiftUI
import MetalKit

struct SunrayView: UIViewRepresentable {
    func makeUIView(context: Context) -> MTKView {
        let mtk = MTKView()
        mtk.device = MTLCreateSystemDefaultDevice()
        mtk.isPaused = false
        mtk.enableSetNeedsDisplay = false
        mtk.preferredFramesPerSecond = 60
        mtk.framebufferOnly = false
        mtk.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        if let renderer = SunrayRenderer(mtkView: mtk) {
            mtk.delegate = renderer
            context.coordinator.renderer = renderer
        }
        mtk.isUserInteractionEnabled = false
        mtk.backgroundColor = .clear
        return mtk
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // keep sun position in corner by default; could be driven by app state
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var renderer: SunrayRenderer?
    }
}

#if os(macOS)
import AppKit
extension SunrayView: NSViewRepresentable {
    func makeNSView(context: Context) -> MTKView {
        let mtk = MTKView()
        mtk.device = MTLCreateSystemDefaultDevice()
        mtk.isPaused = false
        mtk.enableSetNeedsDisplay = false
        mtk.preferredFramesPerSecond = 60
        mtk.framebufferOnly = false
        mtk.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        if let renderer = SunrayRenderer(mtkView: mtk) {
            mtk.delegate = renderer
            context.coordinator.renderer = renderer
        }
        mtk.isUserInteractionEnabled = false
        mtk.wantsLayer = true
        return mtk
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}
}
#endif
