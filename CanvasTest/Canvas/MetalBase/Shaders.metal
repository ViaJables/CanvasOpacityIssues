//
//  Shaders.metal
//  MetalKitTest
//
//  Created by Harley-xk on 2019/3/28.
//  Copyright © 2019 Someone Co.,Ltd. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

//======================================
// Render Target Shaders
//======================================

struct Vertex {
    float4 position [[position]];
    float2 text_coord;
};

struct Uniforms {
    float4x4 scaleMatrix;
};

struct Point {
    float4 position [[position]];
    float4 color;
    float angle;
    float size [[point_size]];
};

struct Transform {
    float2 offset;
    float scale;
};

vertex Vertex vertex_render_target(constant Vertex *vertices [[ buffer(0) ]],
                                   constant Uniforms &uniforms [[ buffer(1) ]],
                                   uint vid [[vertex_id]])
{
    Vertex out = vertices[vid];
    out.position = uniforms.scaleMatrix * out.position;// * in.position;
    return out;
};

fragment float4 fragment_render_target(Vertex vertex_data [[ stage_in ]],
                                       texture2d<float> tex2dcanvas [[ texture(0) ]],
                                       texture2d<float> tex2dbrush [[ texture(1) ]],
                                       constant float &brushOpacity [[ buffer(0) ]],
                                       sampler smpCanvas [[sampler(0)]],
                                       sampler smpBrush [[sampler(1)]])
{
//    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
//    float4 canvasColor = float4(tex2dcanvas.sample(textureSampler, vertex_data.text_coord));
//    float4 brushColor = float4(tex2dbrush.sample(textureSampler, vertex_data.text_coord));
    float4 canvasColor = float4(tex2dcanvas.sample(smpCanvas, vertex_data.text_coord));
    float4 brushColor = float4(tex2dbrush.sample(smpBrush, vertex_data.text_coord));

    float4 out = mix(canvasColor, brushColor, brushOpacity * brushColor.a);
    return out;
};

kernel void kernel_transfer_brush(texture2d<half, access::read_write> tex2dcanvas [[ texture(0) ]],
                                  texture2d<half, access::read_write> tex2dbrush [[ texture(1) ]],
                                  constant float &brushOpacity [[ buffer(0) ]],
                                  uint2 gid [[thread_position_in_grid]]) {
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= tex2dcanvas.get_width()) || (gid.y >= tex2dcanvas.get_height())) {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half4 dst = tex2dcanvas.read(gid);
    half4 src = tex2dbrush.read(gid);
    
    // multiply by brush opacity, then premultiply rgb by alpha
    src.a *= brushOpacity;
    src.rgb *= src.a;

    // compute the blended brush + canvas
    // https://en.wikipedia.org/wiki/Alpha_compositing
    half newAlpha = src.a + dst.a * (1 - src.a);
    half3 newColor;
    if (newAlpha == 0) {
        newColor = 0;
    } else {
        newColor = (src.rgb + dst.rgb * (1 - src.a));
//        newColor = (src.rgb * src.a + dst.rgb * dst.a * (1 - src.a)) / newAlpha;
//        newColor = (src.rgb * src.a + dst.rgb * dst.a * (1 - src.a));
    }
    half4 out = half4(newColor, newAlpha);
    tex2dcanvas.write(out, gid);

    // clear the brush texture
    half4 transparent = half4(0,0,0,0);
    tex2dbrush.write(transparent, gid);
}

float2 transformPointCoord(float2 pointCoord, float a, float2 anchor) {
    float2 point20 = pointCoord - anchor;
    float x = point20.x * cos(a) - point20.y * sin(a);
    float y = point20.x * sin(a) + point20.y * cos(a);
    return float2(x, y) + anchor;
}

//======================================
// Printer Shaders
//======================================
vertex Vertex vertex_printer_func(constant Vertex *vertices [[ buffer(0) ]],
                                  constant Uniforms &uniforms [[ buffer(1) ]],
                                  constant Transform &transform [[ buffer(2) ]],
                                  uint vid [[ vertex_id ]])
{
    Vertex out = vertices[vid];
    float scale = transform.scale;
    float2 offset = transform.offset;
    float2 pos = float2(out.position.x * scale - offset.x, out.position.y * scale - offset.y);
    out.position = uniforms.scaleMatrix * float4(pos, 0, 1);// * in.position;
    return out;
};

//======================================
// Point Shaders
//======================================
vertex Point vertex_point_func(constant Point *points [[ buffer(0) ]],
                               constant Uniforms &uniforms [[ buffer(1) ]],
                               constant Transform &transform [[ buffer(2) ]],
                               uint vid [[ vertex_id ]])
{
    Point out = points[vid];
    float scale = transform.scale;
    float2 offset = transform.offset;
    float2 pos = float2(out.position.x * scale - offset.x, out.position.y * scale - offset.y);
    out.position = uniforms.scaleMatrix * float4(pos, 0, 1);// * in.position;
    out.size = out.size * scale;
    return out;
};

fragment float4 fragment_point_func(Point point_data [[ stage_in ]],
                                    texture2d<float> tex2d [[ texture(0) ]],
                                    float2 pointCoord  [[ point_coord ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float2 text_coord = transformPointCoord(pointCoord, point_data.angle, float2(0.5));
    float4 color = float4(tex2d.sample(textureSampler, text_coord));
    return float4(point_data.color.rgb, color.a * point_data.color.a);
};

// fragment shader for glowing lines
fragment float4 fragment_point_func_glowing(Point point_data [[ stage_in ]],
                                            texture2d<float> tex2d [[ texture(0) ]],
                                            float2 pointCoord  [[ point_coord ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = float4(tex2d.sample(textureSampler, pointCoord));
    if (color.a >= 1) {
        return float4(1, 1, 1, color.a);
    } else if (color.a <= 0) {
        return float4(0);
    }
    return float4(point_data.color.rgb, color.a * point_data.color.a);
};

// fragment shader that applies original color of the texture
fragment half4 fragment_point_func_original(Point point_data [[ stage_in ]],
                                            texture2d<float> tex2d [[ texture(0) ]],
                                            float2 pointCoord  [[ point_coord ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    half4 color = half4(tex2d.sample(textureSampler, pointCoord));
    return half4(color.rgb, color.a * point_data.color.a);
};

fragment float4 fragment_point_func_without_texture(Point point_data [[ stage_in ]],
                                                    float2 pointCoord  [[ point_coord ]])
{
    float dist = length(pointCoord - float2(0.5));
    if (dist >= 0.5) {
        return float4(0);
    }
    return point_data.color;
}
