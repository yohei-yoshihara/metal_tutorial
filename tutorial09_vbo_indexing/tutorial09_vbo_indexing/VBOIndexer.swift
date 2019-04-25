import Foundation
import simd

struct PackedVertex : Hashable {
  var position = float3(0, 0, 0)
  var uv = float2(0, 0)
  var normal = float3(0, 0, 0)
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(position)
    hasher.combine(uv)
    hasher.combine(normal)
  }
}

class VBOIndexer {
  
  func indexVBO(vertices: [float3], uvs: [float2], normals: [float3]) -> (indices: [UInt16], vertices: [float3], uvs: [float2], normals: [float3]) {
    var outIndices = [UInt16]()
    var outVertices = [float3]()
    var outUVs = [float2]()
    var outNormals = [float3]()
    
    var vertexToOutIndex = [PackedVertex: UInt16]()
    
    for i in 0 ..< vertices.count {
      let packed = PackedVertex(position: vertices[i], uv: uvs[i], normal: normals[i])
      if let index = vertexToOutIndex[packed] {
        outIndices.append(index)
      } else {
        outVertices.append(vertices[i])
        outUVs.append(uvs[i])
        outNormals.append(normals[i])
        let newIndex = UInt16(outVertices.count - 1)
        outIndices.append(newIndex)
        vertexToOutIndex[packed] = newIndex
      }
    }
    return (outIndices, outVertices, outUVs, outNormals)
  }
  
}
