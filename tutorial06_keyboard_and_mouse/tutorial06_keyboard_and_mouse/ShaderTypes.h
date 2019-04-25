#ifndef ShaderTypes_h
#define ShaderTypes_h

typedef enum VertexInputIndex {
  VertexInputIndexVertices = 0,
  VertexInputIndexUVs,
  VertexInputIndexMVP,
} VertexInputIndex;

typedef enum FragmentInputIndex {
  FragmentInputIndexTexture = 0,
} FragmentInputIndex;

#endif /* ShaderTypes_h */
