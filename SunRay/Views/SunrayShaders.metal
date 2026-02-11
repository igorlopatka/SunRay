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
    float beamCount;
    float3 color;
};

// Simple hash for noise
float hash(float2 p) {
    float h = dot(p, float2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

// Value noise
float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal noise for cloud-like occlusion
float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

fragment float4 fs_main(VertexOut in [[stage_in]],
                        constant Uniforms& u [[buffer(0)]]) {
    float2 uv = in.uv;
    
    // Sun position (flip y to treat top as 0)
    float2 sunPos = float2(u.sunPos.x, 1.0 - u.sunPos.y);
    
    // Vector from sun to current pixel
    float2 delta = uv - sunPos;
    delta.x *= u.aspect; // Aspect correction
    
    float dist = length(delta);
    float angle = atan2(delta.y, delta.x);
    
    // === RADIAL OCCLUSION PATTERN (clouds/atmosphere blocking rays) ===
    // This creates the characteristic "some rays visible, some blocked" look
    
    float numRays = max(4.0, u.beamCount);
    
    // Rotating angular pattern with time
    float rotatingAngle = angle + u.time * 0.2;
    
    // Create distinct rays using multiple frequencies
    float rayMask = 0.0;
    
    // Primary ray structure
    float primaryRays = sin(rotatingAngle * numRays) * 0.5 + 0.5;
    
    // Add secondary harmonic for more complex ray structure
    float secondaryRays = sin(rotatingAngle * numRays * 2.0 + 1.5) * 0.5 + 0.5;
    
    // Combine ray patterns
    rayMask = primaryRays * 0.7 + secondaryRays * 0.3;
    
    // Apply beam width control - makes rays thinner or thicker
    float widthControl = mix(2.0, 8.0, u.beamWidth);
    rayMask = pow(rayMask, widthControl);
    
    // === OCCLUSION/CLOUD LAYER ===
    // Simulate clouds or atmospheric particles blocking some rays
    
    // Noise pattern that creates cloud-like occlusion
    float2 cloudCoord = float2(rotatingAngle * 2.0, dist * 3.0) + u.time * 0.1;
    float occlusion = fbm(cloudCoord * 1.5);
    
    // Create dramatic light/dark bands (rays breaking through clouds)
    occlusion = smoothstep(0.3, 0.7, occlusion);
    
    // Add radial variation to occlusion
    float2 radialNoise = delta * 1.5 + u.time * 0.05;
    float radialOcclusion = fbm(radialNoise);
    
    // Combine occlusions
    float combinedOcclusion = mix(occlusion, radialOcclusion, 0.4);
    
    // === RADIAL BLUR EFFECT (God Rays) ===
    // Sample along the ray from sun to pixel for volumetric light scattering
    
    const int samples = 16; // More samples for smoother god rays
    float rayAccumulation = 0.0;
    
    for (int i = 0; i < samples; i++) {
        float t = float(i) / float(samples);
        
        // Sample position along ray from sun
        float2 samplePos = sunPos + delta * t;
        samplePos.x /= u.aspect;
        
        float2 sampleDelta = samplePos - float2(u.sunPos.x, 1.0 - u.sunPos.y);
        float sampleAngle = atan2(sampleDelta.y, sampleDelta.x);
        
        // Check if this sample is in a lit ray
        float sampleRotAngle = sampleAngle + u.time * 0.2;
        float sampleRay = sin(sampleRotAngle * numRays) * 0.5 + 0.5;
        sampleRay += sin(sampleRotAngle * numRays * 2.0 + 1.5) * 0.25;
        sampleRay = pow(clamp(sampleRay, 0.0, 1.0), widthControl * 0.7);
        
        // Occlusion at sample point
        float2 sampleCloudCoord = float2(sampleRotAngle * 2.0, t * dist * 3.0) + u.time * 0.1;
        float sampleOcclusion = smoothstep(0.25, 0.65, fbm(sampleCloudCoord * 1.5));
        
        // Weight samples closer to viewer more heavily for god ray effect
        float weight = 1.0 - t * 0.5;
        
        // Accumulate light scattered towards viewer
        rayAccumulation += sampleRay * sampleOcclusion * weight;
    }
    
    rayAccumulation /= float(samples);
    
    // === GOD RAY STREAKS ===
    // Create long, dramatic streaks extending from the sun
    
    // Sharp directional rays
    float streakIntensity = rayMask * combinedOcclusion;
    
    // Make streaks extend further
    float streakFalloff = 1.0 - smoothstep(0.0, 2.5, dist);
    streakFalloff = pow(streakFalloff, 0.6); // Softer falloff for longer rays
    
    // God rays should be brighter and more visible
    float godRays = rayAccumulation * 3.5;
    float streaks = streakIntensity * streakFalloff * 2.5;
    
    // === COMBINE EFFECTS ===
    
    // Distance falloff for overall brightness
    float falloff = exp(-dist * 1.8);
    
    // Very strong central glow
    float coreGlow = exp(-dist * 7.0) * 3.5;
    
    // Combine all ray effects with emphasis on god rays and streaks
    float finalRays = max(godRays, streaks) * falloff;
    
    // Add extra boost to make rays more visible
    finalRays = pow(finalRays, 0.8) * 1.5;
    
    // Combine with core glow
    float brightness = (finalRays + coreGlow * 0.6) * u.intensity;
    
    // Add color variation with distance
    float3 finalColor = mix(u.color, u.color * float3(1.0, 0.92, 0.75), dist * 0.4);
    
    float3 col = finalColor * brightness;
    float alpha = clamp(brightness, 0.0, 1.0);
    
    return float4(col, alpha);
}
