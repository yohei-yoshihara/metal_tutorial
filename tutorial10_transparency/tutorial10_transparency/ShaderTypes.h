#ifndef ShaderTypes_h
#define ShaderTypes_h

typedef enum VertexInputIndex {
  VertexInputIndexVertices = 0,
  VertexInputIndexUVs,
  VertexInputIndexNormals,
  VertexInputIndexMVP,
  VertexInputIndexV,
  VertexInputIndexM,
  VertexInputIndexLightPosition,
} VertexInputIndex;

typedef enum FragmentInputIndex {
  FragmentInputIndexTexture = 0,
  FragmentInputIndexLightPosition,
} FragmentInputIndex;

#endif /* ShaderTypes_h */
