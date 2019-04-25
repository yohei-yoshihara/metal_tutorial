#include <metal_stdlib>
#include <simd/simd.h>
#include "ShaderTypes.h"

using namespace metal;

vertex float4 vertexShader(uint vertexID [[ vertex_id ]],
                           constant float3 *vertexPosition_modelspace [[ buffer(VertexInputIndexVertices) ]]) {
  return float4(vertexPosition_modelspace[vertexID], 1.0);
}

fragment float4 fragmentShader() {
  return float4(1, 0, 0, 1);
}
