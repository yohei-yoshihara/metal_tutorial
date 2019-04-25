import Foundation
import GLKit
import SceneKit
import simd

struct MathUtil {
  static func radian(degree: Float) -> Float {
    return degree * Float.pi / Float(180.0)
  }

  static func degree(radian: Float) -> Float {
    return radian * 180.0 / Float.pi
  }

  static func perspective(fovy: Float, aspect: Float, nearZ: Float, farZ: Float) -> float4x4 {
    let m = GLKMatrix4MakePerspective(fovy, aspect, nearZ, farZ)
    return float4x4(SCNMatrix4FromGLKMatrix4(m))
  }

  static func lookAt(eye: float3, center: float3, up: float3) -> float4x4 {
    let m = GLKMatrix4MakeLookAt(eye.x, eye.y, eye.z, center.x, center.y, center.z, up.x, up.y, up.z)
    return float4x4(SCNMatrix4FromGLKMatrix4(m))
  }
}
