import Cocoa
import Metal
import MetalKit
import simd

class Renderer: NSObject, MTKViewDelegate {
  var device: MTLDevice
  var pipelineState: MTLRenderPipelineState
  var commandQueue: MTLCommandQueue
  var viewportSize = vector_uint2(0, 0)

  init(metalKitView: MTKView) {
    metalKitView.sampleCount = 4
    device = metalKitView.device!
    let defaultLibrary = device.makeDefaultLibrary()!
    let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
    let fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShader")

    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.vertexFunction = vertexFunction
    pipelineStateDescriptor.fragmentFunction = fragmentFunction
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
    pipelineStateDescriptor.sampleCount = metalKitView.sampleCount

    pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)

    commandQueue = device.makeCommandQueue()!
  }

  func mtkView(_: MTKView, drawableSizeWillChange size: CGSize) {
    viewportSize.x = UInt32(size.width)
    viewportSize.y = UInt32(size.height)
  }

  func draw(in view: MTKView) {
    let projectionMatrix = MathUtil.perspective(fovy: MathUtil.radian(degree: 45.0), aspect: 4.0 / 3.0, nearZ: 0.1, farZ: 100.0)
    let viewMatrix = MathUtil.lookAt(eye: float3(4, 3, 3), center: float3(0, 0, 0), up: float3(0, 1, 0))
    let modelMatrix = float4x4(1.0)
    var mvp = projectionMatrix * viewMatrix * modelMatrix

    let commandBuffer = commandQueue.makeCommandBuffer()!

    let renderPassDescriptor = view.currentRenderPassDescriptor!

    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.4, alpha: 0.0)

    let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

    renderEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: -1.0, zfar: 1.0))
    renderEncoder.setRenderPipelineState(pipelineState)

    let g_vertex_buffer_data: [float3] = [
      float3(-1.0, -1.0, 0.0),
      float3(1.0, -1.0, 0.0),
      float3(0.0, 1.0, 0.0),
    ]

    renderEncoder.setVertexBytes(g_vertex_buffer_data,
                                 length: MemoryLayout<float3>.size * g_vertex_buffer_data.count,
                                 index: Int(VertexInputIndexVertices.rawValue))
    renderEncoder.setVertexBytes(&mvp, length: MemoryLayout<float4x4>.size, index: Int(VertexInputIndexMVP.rawValue))

    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

    renderEncoder.endEncoding()

    commandBuffer.present(view.currentDrawable!)

    commandBuffer.commit()
  }
}
