#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vs_main(uint vid [[vertex_id]]) {
    // Fullscreen triangle positions
    float2 pos[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0)
    };
    VertexOut out;
    out.position = float4(pos[vid], 0.0, 1.0);
    // Map NDC to [0,1] UV
    out.uv = 0.5 * (pos[vid] + float2(1.0, 1.0));
    return out;
}

struct Uniforms {
    float2 sunPos;
    float time;
    float intensity;
    float aspect;
    float beamWidth;
    float3 color;
};

fragment float4 fs_main(VertexOut in [[stage_in]],
                        constant Uniforms& u [[buffer(0)]]) {
    // UV in [0,1]; flip Y if needed to match your coordinate convention
    float2 uv = in.uv;

    // Distance and angle from sun position (note: flip y to treat top as 0)
    float2 d = float2(uv.x, 1.0 - uv.y) - u.sunPos;

    // Correct for aspect ratio so circles look round
    d.x *= u.aspect;

    float r = length(d) + 1e-5;
    float angle = atan2(d.y, d.x);

    // Radial beam pattern: angular lobes (no inverse-radius spiral term)
    float angularFreq = 12.0; // number of beams around the sun
    float phase = u.time * 0.5;
    float raw = cos(angularFreq * angle + phase);
    float beams = pow(abs(raw), 1.0 + max(0.0, u.beamWidth) * 3.0);

    // Soft edge for beams: sharpen or soften using smoothstep
    float beam = smoothstep(0.15, 0.95, beams);

    // Smooth radial falloff (soft sunglow)
    float falloff = exp(-r * 3.0);

    float brightness = u.intensity * beam * falloff;
    float3 col = u.color * brightness;

    // Semi-transparent so it composites over UI beneath
    float alpha = clamp(brightness, 0.0, 1.0);
    return float4(col, alpha);
}
