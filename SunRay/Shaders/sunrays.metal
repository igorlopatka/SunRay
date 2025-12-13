#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vs_main(uint vid [[vertex_id]]) {
    float2 positions[3] = { {-1.0, -1.0}, {3.0, -1.0}, {-1.0, 3.0} };
    float2 pos = positions[vid];
    VertexOut out;
    out.position = float4(pos, 0.0, 1.0);
    out.uv = pos * 0.5 + 0.5;
    return out;
}

struct Uniforms {
    float2 sunPos; // normalized 0..1
    float time;
    float intensity;
    float aspect;
    float beamWidth;
    float3 color;
};

// simple pseudo-noise for variation
float noise(float2 v) {
    return fract(sin(dot(v, float2(12.9898,78.233))) * 43758.5453);
}

fragment float4 fs_main(VertexOut in [[stage_in]], constant Uniforms& u [[buffer(0)]]) {
    float2 uv = in.uv;

    // compute vector from sun to this fragment
    float2 dir = uv - u.sunPos;
    dir.x *= u.aspect; // compensate aspect
    float dist = length(dir);
    float2 dirN = dir / max(dist, 1e-6);

    // sample along the ray towards the sun
    const int STEPS = 24;
    float sum = 0.0;
    float decay = 0.92;
    float t = 0.0;
    for (int i = 0; i < STEPS; i++) {
        float step = (float(i) / float(STEPS));
        float2 samplePos = mix(uv, u.sunPos, step);
        float n = noise(samplePos * (6.0 + u.time * 0.05));
        float beam = smoothstep(u.beamWidth, 0.0, distance(samplePos, u.sunPos));
        float v = n * beam * pow(decay, float(i));
        sum += v;
    }

    // attenuate by distance from sun
    float falloff = smoothstep(1.0, 0.0, dist);
    float intensity = sum * u.intensity * falloff;

    float3 col = u.color * intensity;
    return float4(col, intensity);
}
