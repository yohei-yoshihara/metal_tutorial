#include <metal_stdlib>
#include <simd/simd.h>
#include "ShaderTypes.h"

using namespace metal;

typedef struct {
  float4 pos [[position]];
  float4 color;
} RasterizerData;

vertex RasterizerData vertexShader(uint vertexID [[ vertex_id ]],
                           constant float3 *vertexPosition_modelspace [[ buffer(VertexInputIndexVertices) ]],
                           constant float3 *vertexColor [[ buffer(VertexInputIndexColors) ]],
                           constant float4x4 *MVP [[ buffer(VertexInputIndexMVP) ]]) {
  RasterizerData out;
  out.pos = *MVP * float4(vertexPosition_modelspace[vertexID], 1.0);
  out.color = float4(vertexColor[vertexID], 1.0);
  return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]]) {
  return in.color;
}
