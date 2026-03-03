#include <metal_stdlib>
using namespace metal;

// MARK: - Vertex Input/Output

struct StrokeVertex {
    float2 position;
    float4 color;
    float thickness;
    float opacity;
    float2 texCoord;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float thickness;
    float opacity;
    float2 texCoord;
};

struct Uniforms {
    float2 viewportSize;
};

// MARK: - Standard Stroke Shaders

vertex VertexOut strokeVertexShader(
    const device StrokeVertex* vertices [[buffer(0)]],
    const device Uniforms& uniforms [[buffer(1)]],
    uint vid [[vertex_id]]
) {
    VertexOut out;
    StrokeVertex v = vertices[vid];
    
    // Position is already in NDC (-1 to 1) from the renderer
    out.position = float4(v.position, 0.0, 1.0);
    out.color = v.color;
    out.thickness = v.thickness;
    out.opacity = v.opacity;
    out.texCoord = v.texCoord;
    
    return out;
}

fragment float4 strokeFragmentShader(VertexOut in [[stage_in]]) {
    float4 color = in.color;
    
    // Soft edge falloff based on distance from center of stroke (texCoord.x: 0=edge, 0.5=center, 1=edge)
    float distFromCenter = abs(in.texCoord.x - 0.5) * 2.0; // 0 at center, 1 at edge
    float edgeSoftness = 1.0 - smoothstep(0.7, 1.0, distFromCenter);
    
    color.a *= edgeSoftness;
    
    return color;
}

// MARK: - Highlighter Shader (translucent wash effect)

fragment float4 highlighterFragmentShader(VertexOut in [[stage_in]]) {
    float4 color = in.color;
    
    // Highlighter: uniform opacity across the stroke width, no edge falloff
    // This creates the "wash" effect of a real highlighter
    float distFromCenter = abs(in.texCoord.x - 0.5) * 2.0;
    float edgeSoftness = 1.0 - smoothstep(0.85, 1.0, distFromCenter);
    
    color.a *= edgeSoftness * in.opacity;
    
    return color;
}

// MARK: - Pencil Shader (graphite grain texture)

fragment float4 pencilFragmentShader(VertexOut in [[stage_in]]) {
    float4 color = in.color;
    
    // Procedural grain noise
    float2 uv = in.texCoord * 50.0;
    float noise = fract(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
    
    // Graphite look: vary alpha with grain
    float grainAlpha = 0.5 + noise * 0.5;
    color.a *= grainAlpha * in.opacity;
    
    // Edge softness
    float distFromCenter = abs(in.texCoord.x - 0.5) * 2.0;
    float edgeSoftness = 1.0 - smoothstep(0.6, 1.0, distFromCenter);
    color.a *= edgeSoftness;
    
    return color;
}

// MARK: - Crayon Shader (waxy grain texture)

fragment float4 crayonFragmentShader(VertexOut in [[stage_in]]) {
    float4 color = in.color;
    
    // Waxy grain: larger, more structured noise
    float2 uv = in.texCoord * 20.0;
    float noise1 = fract(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
    float noise2 = fract(sin(dot(uv * 2.0, float2(39.346, 11.135))) * 23421.631);
    float grain = mix(noise1, noise2, 0.5);
    
    // Rough edges
    float distFromCenter = abs(in.texCoord.x - 0.5) * 2.0;
    float roughEdge = 1.0 - smoothstep(0.5, 0.9 + grain * 0.1, distFromCenter);
    
    color.a *= (0.6 + grain * 0.4) * roughEdge * in.opacity;
    
    return color;
}

// MARK: - Watercolor Shader (feathered edges, translucent)

fragment float4 watercolorFragmentShader(VertexOut in [[stage_in]]) {
    float4 color = in.color;
    
    // Very soft, feathered edges
    float distFromCenter = abs(in.texCoord.x - 0.5) * 2.0;
    float feather = 1.0 - smoothstep(0.3, 1.0, distFromCenter);
    
    // Slight flow variation along the stroke
    float2 uv = in.texCoord * 10.0;
    float flow = 0.8 + 0.2 * sin(uv.y * 3.14159);
    
    // Water pooling effect: slightly darker at edges
    float pooling = 1.0 + 0.15 * smoothstep(0.4, 0.7, distFromCenter);
    
    color.rgb *= pooling;
    color.a *= feather * flow * in.opacity;
    
    return color;
}

// MARK: - Calligraphy Shader (clean edges, varying width handled by vertex)

fragment float4 calligraphyFragmentShader(VertexOut in [[stage_in]]) {
    float4 color = in.color;
    
    // Sharp, clean edges for calligraphy
    float distFromCenter = abs(in.texCoord.x - 0.5) * 2.0;
    float edgeSoftness = 1.0 - smoothstep(0.85, 0.95, distFromCenter);
    
    color.a *= edgeSoftness * in.opacity;
    
    return color;
}

// MARK: - Laser Pointer Shader (bright glow)

fragment float4 laserPointerFragmentShader(VertexOut in [[stage_in]]) {
    float4 color = in.color;
    
    // Bright core with glow falloff
    float distFromCenter = abs(in.texCoord.x - 0.5) * 2.0;
    float core = 1.0 - smoothstep(0.0, 0.3, distFromCenter);
    float glow = 1.0 - smoothstep(0.0, 1.0, distFromCenter);
    
    // Bright, saturated core
    float brightness = core * 1.5 + glow * 0.5;
    color.rgb = min(color.rgb * brightness, float3(1.0));
    color.a *= glow * in.opacity;
    
    return color;
}
