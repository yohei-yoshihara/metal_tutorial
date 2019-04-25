import Cocoa
import MetalKit

class ViewController: NSViewController {
  var renderer: Renderer!

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewDidAppear() {
    super.viewDidAppear()

    guard let view = self.view as? ControlView else {
      fatalError()
    }
    guard let viewDisplayID = view.window?.screen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
      fatalError()
    }
    let device = CGDirectDisplayCopyCurrentMetalDevice(viewDisplayID)
    view.device = device
    renderer = Renderer(metalKitView: view)
    renderer.mtkView(view, drawableSizeWillChange: view.drawableSize)
    view.delegate = renderer
    view.controlViewdelegate = renderer

    view.window?.makeFirstResponder(view)
  }
}
