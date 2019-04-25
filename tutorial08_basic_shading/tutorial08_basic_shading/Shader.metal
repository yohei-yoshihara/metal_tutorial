#include <metal_stdlib>
#include <simd/simd.h>
#include "ShaderTypes.h"

using namespace metal;

typedef struct {
  float4 pos [[position]];
  float3 positionWorldspace;
  float2 uv;
  float3 normalCameraspace;
  float3 eyeDirectionCameraspace;
  float3 lightDirectionCameraspace;
} RasterizerData;

vertex RasterizerData vertexShader(uint vertexID [[ vertex_id ]],
                                   constant float3 *vertexPosition_modelspace [[ buffer(VertexInputIndexVertices) ]],
                                   constant float2 *vertexUV [[ buffer(VertexInputIndexUVs) ]],
                                   constant float3 *vertexNormal_modelspace [[ buffer(VertexInputIndexNormals) ]],
                                   constant float4x4 *MVP [[ buffer(VertexInputIndexMVP) ]],
                                   constant float4x4 *V [[ buffer(VertexInputIndexV) ]],
                                   constant float4x4 *M [[ buffer(VertexInputIndexM) ]],
                                   constant float3 *lightPositionWorldspace [[ buffer(VertexInputIndexLightPosition) ]]) {
  RasterizerData out;
  out.pos = *MVP * float4(vertexPosition_modelspace[vertexID], 1.0);
  out.positionWorldspace = (*M * float4(vertexPosition_modelspace[vertexID], 1.0)).xyz;
  
  float3 vertexPositionCameraspace = (*V * *M * float4(vertexPosition_modelspace[vertexID], 1.0)).xyz;
  out.eyeDirectionCameraspace = float3(0, 0, 0) - vertexPositionCameraspace;
  
  float3 lightPositionCameraspace = (*V * float4(*lightPositionWorldspace, 1.0)).xyz;
  out.lightDirectionCameraspace = lightPositionCameraspace + out.eyeDirectionCameraspace;
  
  out.normalCameraspace = (*V * *M * float4(vertexNormal_modelspace[vertexID], 0.0)).xyz;
  
  out.uv = vertexUV[vertexID];
  return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]],
                               texture2d<half> texture [[ texture(FragmentInputIndexTexture) ]],
                               constant float3 *lightPositionWorldspace [[ buffer(FragmentInputIndexLightPosition) ]]) {
  constexpr sampler textureSampler(mag_filter::linear,
                                   min_filter::linear);

  float3 lightColor(1, 1, 1);
  float lightPower = 50.0;
  
  float3 materialDiffuseColor = float3(texture.sample(textureSampler, in.uv).rgb);
  float3 materialAmbientColor = float3(0.1, 0.1, 0.1) * materialDiffuseColor;
  float3 materialSpecularColor = float3(0.3, 0.3, 0.3);
  
  float distance = length(*lightPositionWorldspace - in.positionWorldspace);
  
  float3 n = normalize(in.normalCameraspace);
  float3 l = normalize(in.lightDirectionCameraspace);
  float cosTheta = clamp(dot(n, l), 0, 1);
  
  float3 E = normalize(in.eyeDirectionCameraspace);
  float3 R = reflect(-l, n);
  float cosAlpha = clamp(dot(E, R), 0, 1);
  
  float3 color =
    materialAmbientColor +
    materialDiffuseColor * lightColor * lightPower * cosTheta / (distance*distance) +
    materialSpecularColor * lightColor * lightPower * pow(cosAlpha, 5) / (distance*distance);
  
  return float4(color, 1);
}
