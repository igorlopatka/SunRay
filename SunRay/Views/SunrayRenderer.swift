import Foundation
import MetalKit

import os

final class SunrayRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private var pipelineState: MTLRenderPipelineState!
    private var startTime = CFAbsoluteTimeGetCurrent()
    private var commandQueue: MTLCommandQueue!

    struct Uniforms {
        var sunPos: SIMD2<Float>
        var time: Float
        var intensity: Float
        var aspect: Float
        var beamWidth: Float
        var color: SIMD3<Float>
    }

    var sunPosition: CGPoint = CGPoint(x: 0.85, y: 0.15)
    var intensity: Float = 1.0
    var color: SIMD3<Float> = SIMD3(1.0, 0.85, 0.6)

    init?(mtkView: MTKView) {
        guard let device = mtkView.device else { return nil }
        self.device = device
        super.init()
        commandQueue = device.makeCommandQueue()

        do {
            let lib: MTLLibrary
            if let defaultLib = device.makeDefaultLibrary() {
                lib = defaultLib
            } else {
                lib = try device.makeDefaultLibrary(bundle: .main)
            }

            guard let vfn = lib.makeFunction(name: "vs_main"), let ffn = lib.makeFunction(name: "fs_main") else {
                SRLog("SunrayRenderer: shader functions not found in library", level: .error)
                return nil
            }

            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction = vfn
            desc.fragmentFunction = ffn
            desc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
            if let att = desc.colorAttachments[0] {
                att.isBlendingEnabled = true
                att.rgbBlendOperation = .add
                att.alphaBlendOperation = .add
                att.sourceRGBBlendFactor = .sourceAlpha
                att.destinationRGBBlendFactor = .oneMinusSourceAlpha
                att.sourceAlphaBlendFactor = .one
                att.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            }
            pipelineState = try device.makeRenderPipelineState(descriptor: desc)
        } catch {
            SRLog("SunrayRenderer init failed: \(error)", level: .error)
            return nil
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // no-op
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else { return }

        let now = Float(CFAbsoluteTimeGetCurrent() - startTime)
        let aspect = Float(view.drawableSize.width / max(1.0, view.drawableSize.height))

        var uniforms = Uniforms(
            sunPos: SIMD2(Float(sunPosition.x), Float(sunPosition.y)),
            time: now,
            intensity: intensity,
            aspect: aspect,
            beamWidth: 0.5,
            color: color
        )

        guard let cmdBuf = commandQueue.makeCommandBuffer(),
              let encoder = cmdBuf.makeRenderCommandEncoder(descriptor: descriptor) else { return }

        // Ensure viewport matches drawable size
        encoder.setViewport(MTLViewport(
            originX: 0,
            originY: 0,
            width: Double(view.drawableSize.width),
            height: Double(view.drawableSize.height),
            znear: 0,
            zfar: 1
        ))

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        cmdBuf.present(drawable)
        cmdBuf.commit()
    }
}

