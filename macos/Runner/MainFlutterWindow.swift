import Cocoa
import FlutterMacOS
import desktop_multi_window

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
        RegisterGeneratedPlugins(registry: controller)
        if let window = controller.view.window {
            window.setFrame(NSRect(x: 0, y: 0, width: 1100, height: 650), display: true)
            window.center()
        }
    }

    super.awakeFromNib()
  }
}
