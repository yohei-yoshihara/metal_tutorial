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
  var texture: MTLTexture

  init(metalKitView: MTKView) {
    metalKitView.colorPixelFormat = .bgra8Unorm
    metalKitView.depthStencilPixelFormat = .depth32Float
    metalKitView.sampleCount = 4

    device = metalKitView.device!
    let defaultLibrary = device.makeDefaultLibrary()!
    let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
    let fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShader")

    // load the texture
    guard let textureURL = Bundle.main.url(forResource: "uvtemplate", withExtension: "png") else { fatalError() }
    let textureLoader = MTKTextureLoader(device: device)
    texture = try! textureLoader.newTexture(URL: textureURL, options: nil)

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
    renderEncoder.setVertexBytes(g_uv_buffer_data,
                                 length: MemoryLayout<float2>.size * g_uv_buffer_data.count,
                                 index: Int(VertexInputIndexUVs.rawValue))
    renderEncoder.setVertexBytes(&MVP, length: MemoryLayout<float4x4>.size,
                                 index: Int(VertexInputIndexMVP.rawValue))

    renderEncoder.setFragmentTexture(texture,
                                     index: Int(FragmentInputIndexTexture.rawValue))

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

  let g_uv_buffer_data: [float2] = [
    float2(5.9e-05, 3.99351e-06),
    float2(0.000103, 0.336048),
    float2(0.335973, 0.335903),
    float2(1.00002, 1.29938e-05),
    float2(0.667979, 0.335851),
    float2(0.999958, 0.336064),
    float2(0.667979, 0.335851),
    float2(0.336024, 0.671877),
    float2(0.667969, 0.671889),
    float2(1.00002, 1.29938e-05),
    float2(0.668104, 1.29938e-05),
    float2(0.667979, 0.335851),
    float2(5.9e-05, 3.99351e-06),
    float2(0.335973, 0.335903),
    float2(0.336098, 7.09891e-05),
    float2(0.667979, 0.335851),
    float2(0.335973, 0.335903),
    float2(0.336024, 0.671877),
    float2(1, 0.671847),
    float2(0.999958, 0.336064),
    float2(0.667979, 0.335851),
    float2(0.668104, 1.29938e-05),
    float2(0.335973, 0.335903),
    float2(0.667979, 0.335851),
    float2(0.335973, 0.335903),
    float2(0.668104, 1.29938e-05),
    float2(0.336098, 7.09891e-05),
    float2(0.000103, 0.336048),
    float2(4e-06, 0.67187),
    float2(0.336024, 0.671877),
    float2(0.000103, 0.336048),
    float2(0.336024, 0.671877),
    float2(0.335973, 0.335903),
    float2(0.667969, 0.671889),
    float2(1, 0.671847),
    float2(0.667979, 0.335851),
  ]
}
