#include <metal_stdlib>
#include <simd/simd.h>
#include "ShaderTypes.h"

using namespace metal;

typedef struct {
  float4 pos [[position]];
  float2 uv;
} RasterizerData;

vertex RasterizerData vertexShader(uint vertexID [[ vertex_id ]],
                                   constant float3 *vertexPosition_modelspace [[ buffer(VertexInputIndexVertices) ]],
                                   constant float2 *vertexUV [[ buffer(VertexInputIndexUVs) ]],
                                   constant float4x4 *MVP [[ buffer(VertexInputIndexMVP) ]]) {
  RasterizerData out;
  out.pos = *MVP * float4(vertexPosition_modelspace[vertexID], 1.0);
  out.uv = vertexUV[vertexID];
  return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               texture2d<half> texture [[ texture(FragmentInputIndexTexture) ]]) {
  constexpr sampler textureSampler(mag_filter::linear,
                                   min_filter::linear);
  
  const half4 colorSample = texture.sample(textureSampler, in.uv);
  return float4(colorSample);
}
