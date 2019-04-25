import Foundation
import os.log
import simd

class ObjectLoader {
  func load(url: URL) throws -> (vertices: [float3], uvs: [float2], normals: [float3])? {
    var vertexIndices = [Int]()
    var uvIndices = [Int]()
    var normalIndices = [Int]()
    var temp_vertices = [float3]()
    var temp_uvs = [float2]()
    var temp_normals = [float3]()

    let s = try String(contentsOf: url)
    let lines = s.components(separatedBy: .newlines)

    for line in lines {
      if line.starts(with: "v ") {
        let ss = String(line[line.index(line.startIndex, offsetBy: 2) ..< line.endIndex])
        let sarray = ss.components(separatedBy: .whitespaces)
        guard sarray.count == 3 else { return nil }
        guard let v0 = Float32(sarray[0]),
          let v1 = Float32(sarray[1]),
          let v2 = Float32(sarray[2]) else { return nil }
        temp_vertices.append(float3(v0, v1, v2))
      } else if line.starts(with: "vt ") {
        let ss = String(line[line.index(line.startIndex, offsetBy: 3) ..< line.endIndex])
        let sarray = ss.components(separatedBy: .whitespaces)
        guard sarray.count == 2 else { return nil }
        guard let t0 = Float32(sarray[0]),
          let t1 = Float32(sarray[1]) else { return nil }
        temp_uvs.append(float2(t0, 1 - t1))
      } else if line.starts(with: "vn ") {
        let ss = String(line[line.index(line.startIndex, offsetBy: 3) ..< line.endIndex])
        let sarray = ss.components(separatedBy: .whitespaces)
        guard sarray.count == 3 else { return nil }
        guard let n0 = Float32(sarray[0]),
          let n1 = Float32(sarray[1]),
          let n2 = Float32(sarray[2]) else { return nil }
        temp_normals.append(float3(n0, n1, n2))
      } else if line.starts(with: "f ") {
        let ss = String(line[line.index(line.startIndex, offsetBy: 2) ..< line.endIndex])
        let triangle = ss.components(separatedBy: .whitespaces)
        guard triangle.count == 3 else { return nil }
        for i in 0 ..< 3 {
          let array = triangle[i].components(separatedBy: "/")
          guard let vIdx = Int(array[0]) else { return nil }
          vertexIndices.append(vIdx)
          guard let uvIdx = Int(array[1]) else { return nil }
          uvIndices.append(uvIdx)
          guard let nIdx = Int(array[2]) else { return nil }
          normalIndices.append(nIdx)
        }
      }
    }

    var out_vertices = [float3]()
    var out_uvs = [float2]()
    var out_normals = [float3]()
    for i in 0 ..< vertexIndices.count {
      let vertexIndex = vertexIndices[i]
      let uvIndex = uvIndices[i]
      let normalIndex = normalIndices[i]

      let vertex = temp_vertices[vertexIndex - 1]
      let uv = temp_uvs[uvIndex - 1]
      let normal = temp_normals[normalIndex - 1]

      out_vertices.append(vertex)
      out_uvs.append(uv)
      out_normals.append(normal)
    }
    return (out_vertices, out_uvs, out_normals)
  }
}
