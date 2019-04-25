import Cocoa
import Metal
import MetalKit
import simd

class Renderer: NSObject, MTKViewDelegate, ControlViewDelegate {
  var device: MTLDevice
  var depthStencilState: MTLDepthStencilState
  var pipelineState: MTLRenderPipelineState
  var commandQueue: MTLCommandQueue
  var viewportSize = vector_uint2(0, 0)
  var texture: MTLTexture

  var vertices: [float3]
  var uvs: [float2]

  init(metalKitView: MTKView) {
    metalKitView.depthStencilPixelFormat = .depth32Float
    metalKitView.colorPixelFormat = .bgra8Unorm
    metalKitView.sampleCount = 4

    device = metalKitView.device!
    let defaultLibrary = device.makeDefaultLibrary()!
    let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
    let fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShader")

    // load the texture
    guard let textureURL = Bundle.main.url(forResource: "uvmap", withExtension: "png") else { fatalError() }
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

    guard let url = Bundle.main.url(forResource: "cube", withExtension: "obj") else { fatalError() }
    guard let (vertices, uvs, _) = try? ObjectLoader().load(url: url) else { fatalError() }
    self.vertices = vertices
    self.uvs = uvs
  }

  func mtkView(_: MTKView, drawableSizeWillChange size: CGSize) {
    viewportSize.x = UInt32(size.width)
    viewportSize.y = UInt32(size.height)
  }

  var direction = float3(0, 0, -1)
  var right = float3(1, 0, 0)
  var up = float3(0, 1, 0)
  var position = float3(0, 0, 5)
  var horizontalAngle: Float = Float.pi
  var verticalAngle: Float = 0.0
  var initialFoV: Float = 45.0
  var speed: Float = 0.3
  var mouseSpeed: Float = 0.005 // 0.005

  var lastTime = CFTimeInterval(0.0)

  func controlView(mouseMoved point: NSPoint) {
    // Compute new orientation
    let deltaH = mouseSpeed * Float(-point.x)
    let deltaV = mouseSpeed * Float(point.y)
    horizontalAngle += deltaH
    verticalAngle += deltaV

    direction = float3(
      cos(verticalAngle) * sin(horizontalAngle),
      sin(verticalAngle),
      cos(verticalAngle) * cos(horizontalAngle)
    )

    right = float3(
      sin(horizontalAngle - Float.pi / 2.0),
      0,
      cos(horizontalAngle - Float.pi / 2.0)
    )

    up = cross(right, direction)
    computeMatricesFromInputs()
  }

  func controlView(keyDown keyCode: UInt16) {
    if keyCode == 126 {
      position += direction * speed
    }
    if keyCode == 125 {
      position -= direction * speed
    }
    if keyCode == 123 {
      position += right * speed
    }
    if keyCode == 124 {
      position -= right * speed
    }
    computeMatricesFromInputs()
  }

  var projectionMatrix = float4x4(1.0)
  var viewMatrix = float4x4(1.0)

  func computeMatricesFromInputs() {
    let FoV = initialFoV
    projectionMatrix = MathUtil.perspective(fovy: MathUtil.radian(degree: FoV), aspect: 4.0 / 3.0, nearZ: 0.1, farZ: 100.0)
    viewMatrix = MathUtil.lookAt(eye: position, center: position + direction, up: up)
  }

  func draw(in view: MTKView) {
    computeMatricesFromInputs()
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

    renderEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: -1.0, zfar: 1.0))
    renderEncoder.setRenderPipelineState(pipelineState)

    renderEncoder.setVertexBytes(vertices,
                                 length: MemoryLayout<float3>.size * vertices.count,
                                 index: Int(VertexInputIndexVertices.rawValue))
    renderEncoder.setVertexBytes(uvs,
                                 length: MemoryLayout<float2>.size * uvs.count,
                                 index: Int(VertexInputIndexUVs.rawValue))
    renderEncoder.setVertexBytes(&MVP, length: MemoryLayout<float4x4>.size,
                                 index: Int(VertexInputIndexMVP.rawValue))

    renderEncoder.setFragmentTexture(texture,
                                     index: Int(FragmentInputIndexTexture.rawValue))

    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)

    renderEncoder.endEncoding()

    commandBuffer.present(view.currentDrawable!)

    commandBuffer.commit()
  }
}
