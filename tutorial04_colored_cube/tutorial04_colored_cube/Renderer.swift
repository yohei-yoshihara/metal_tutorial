import Cocoa
import Metal
import MetalKit
import simd

class Renderer: NSObject, MTKViewDelegate {
  var device: MTLDevice
  var depthStencilState: MTLDepthStencilState
  var pipelineState: MTLRenderPipelineState
  var commandQueue: MTLCommandQueue
  var viewportSize = vector_uint2(0, 0)

  init(metalKitView: MTKView) {
    metalKitView.colorPixelFormat = .bgra8Unorm
    metalKitView.depthStencilPixelFormat = .depth32Float
    metalKitView.sampleCount = 4

    device = metalKitView.device!
    let defaultLibrary = device.makeDefaultLibrary()!
    let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
    let fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShader")

    // create a depth buffer
    let depthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStencilDescriptor.depthCompareFunction = .less
    depthStencilDescriptor.isDepthWriteEnabled = true
    depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!

    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.vertexFunction = vertexFunction
    pipelineStateDescriptor.fragmentFunction = fragmentFunction
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
    pipelineStateDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
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
    let viewMatrix = MathUtil.lookAt(eye: float3(4, 3, -3), center: float3(0, 0, 0), up: float3(0, 1, 0))
    let modelMatrix = float4x4(1.0)
    var MVP = projectionMatrix * viewMatrix * modelMatrix

    let commandBuffer = commandQueue.makeCommandBuffer()!

    let renderPassDescriptor = view.currentRenderPassDescriptor!
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.4, alpha: 0.0)
    renderPassDescriptor.depthAttachment.loadAction = .clear
    renderPassDescriptor.depthAttachment.clearDepth = 1.0

    let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

    renderEncoder.setDepthStencilState(depthStencilState)
//    renderEncoder.setFrontFacing(.counterClockwise)
//    renderEncoder.setCullMode(.back)

    renderEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: -1.0, zfar: 1.0))
    renderEncoder.setRenderPipelineState(pipelineState)

    renderEncoder.setVertexBytes(g_vertex_buffer_data,
                                 length: MemoryLayout<float3>.size * g_vertex_buffer_data.count,
                                 index: Int(VertexInputIndexVertices.rawValue))
    renderEncoder.setVertexBytes(g_color_buffer_data,
                                 length: MemoryLayout<float3>.size * g_color_buffer_data.count,
                                 index: Int(VertexInputIndexColors.rawValue))
    renderEncoder.setVertexBytes(&MVP, length: MemoryLayout<float4x4>.size,
                                 index: Int(VertexInputIndexMVP.rawValue))

    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 12 * 3)

    renderEncoder.endEncoding()

    commandBuffer.present(view.currentDrawable!)

    commandBuffer.commit()
  }

  let g_vertex_buffer_data: [float3] = [
    float3(-1.0, -1.0, -1.0),
    float3(-1.0, -1.0, 1.0),
    float3(-1.0, 1.0, 1.0),
    float3(1.0, 1.0, -1.0),
    float3(-1.0, -1.0, -1.0),
    float3(-1.0, 1.0, -1.0),
    float3(1.0, -1.0, 1.0),
    float3(-1.0, -1.0, -1.0),
    float3(1.0, -1.0, -1.0),
    float3(1.0, 1.0, -1.0),
    float3(1.0, -1.0, -1.0),
    float3(-1.0, -1.0, -1.0),
    float3(-1.0, -1.0, -1.0),
    float3(-1.0, 1.0, 1.0),
    float3(-1.0, 1.0, -1.0),
    float3(1.0, -1.0, 1.0),
    float3(-1.0, -1.0, 1.0),
    float3(-1.0, -1.0, -1.0),
    float3(-1.0, 1.0, 1.0),
    float3(-1.0, -1.0, 1.0),
    float3(1.0, -1.0, 1.0),
    float3(1.0, 1.0, 1.0),
    float3(1.0, -1.0, -1.0),
    float3(1.0, 1.0, -1.0),
    float3(1.0, -1.0, -1.0),
    float3(1.0, 1.0, 1.0),
    float3(1.0, -1.0, 1.0),
    float3(1.0, 1.0, 1.0),
    float3(1.0, 1.0, -1.0),
    float3(-1.0, 1.0, -1.0),
    float3(1.0, 1.0, 1.0),
    float3(-1.0, 1.0, -1.0),
    float3(-1.0, 1.0, 1.0),
    float3(1.0, 1.0, 1.0),
    float3(-1.0, 1.0, 1.0),
    float3(1.0, -1.0, 1.0),
  ]

  let g_color_buffer_data: [float3] = [
    float3(0.583, 0.771, 0.014),
    float3(0.609, 0.115, 0.436),
    float3(0.327, 0.483, 0.844),
    float3(0.822, 0.569, 0.201),
    float3(0.435, 0.602, 0.223),
    float3(0.310, 0.747, 0.185),
    float3(0.597, 0.770, 0.761),
    float3(0.559, 0.436, 0.730),
    float3(0.359, 0.583, 0.152),
    float3(0.483, 0.596, 0.789),
    float3(0.559, 0.861, 0.639),
    float3(0.195, 0.548, 0.859),
    float3(0.014, 0.184, 0.576),
    float3(0.771, 0.328, 0.970),
    float3(0.406, 0.615, 0.116),
    float3(0.676, 0.977, 0.133),
    float3(0.971, 0.572, 0.833),
    float3(0.140, 0.616, 0.489),
    float3(0.997, 0.513, 0.064),
    float3(0.945, 0.719, 0.592),
    float3(0.543, 0.021, 0.978),
    float3(0.279, 0.317, 0.505),
    float3(0.167, 0.620, 0.077),
    float3(0.347, 0.857, 0.137),
    float3(0.055, 0.953, 0.042),
    float3(0.714, 0.505, 0.345),
    float3(0.783, 0.290, 0.734),
    float3(0.722, 0.645, 0.174),
    float3(0.302, 0.455, 0.848),
    float3(0.225, 0.587, 0.040),
    float3(0.517, 0.713, 0.338),
    float3(0.053, 0.959, 0.120),
    float3(0.393, 0.621, 0.362),
    float3(0.673, 0.211, 0.457),
    float3(0.820, 0.883, 0.371),
    float3(0.982, 0.099, 0.879),
  ]
}
