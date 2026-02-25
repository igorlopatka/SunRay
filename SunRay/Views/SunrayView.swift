#if canImport(UIKit)
import SwiftUI
import MetalKit
import os

struct SunrayView: UIViewRepresentable {
    var uvIndex: Float = 5.0

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
        } else {
            SRLog("SunrayView: SunrayRenderer failed to initialize; Metal overlay disabled", level: .error)
        }
        mtk.isUserInteractionEnabled = false
        mtk.backgroundColor = .clear
        return mtk
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.renderer?.uvIndex = uvIndex
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var renderer: SunrayRenderer?
    }
}

#elseif canImport(AppKit)
import SwiftUI
import MetalKit
import AppKit
import os

struct SunrayView: NSViewRepresentable {
    var uvIndex: Float = 5.0

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
        } else {
            SRLog("SunrayView (macOS): SunrayRenderer failed to initialize; Metal overlay disabled", level: .error)
        }
        mtk.isUserInteractionEnabled = false
        mtk.wantsLayer = true
        return mtk
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.renderer?.uvIndex = uvIndex
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var renderer: SunrayRenderer?
    }
}
#endif
