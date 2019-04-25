import Cocoa
import MetalKit

protocol ControlViewDelegate: class {
  func controlView(mouseMoved: NSPoint)
  func controlView(keyDown: UInt16)
}

class ControlView: MTKView {
  weak var controlViewdelegate: ControlViewDelegate?

  var last = CGPoint.zero

  override func mouseDown(with event: NSEvent) {
    last = convert(event.locationInWindow, from: nil)
  }

  override func mouseDragged(with event: NSEvent) {
    let current = convert(event.locationInWindow, from: nil)
    controlViewdelegate?.controlView(mouseMoved: CGPoint(x: current.x - last.x, y: current.y - last.y))
    last = current
  }

  override func mouseUp(with event: NSEvent) {
    let current = convert(event.locationInWindow, from: nil)
    controlViewdelegate?.controlView(mouseMoved: CGPoint(x: current.x - last.x, y: current.y - last.y))
    last = current
  }

  override func keyDown(with event: NSEvent) {
    let keyCode = event.keyCode
    controlViewdelegate?.controlView(keyDown: keyCode)
  }

  override func becomeFirstResponder() -> Bool {
    return true
  }
}
