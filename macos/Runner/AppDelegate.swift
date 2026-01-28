import Cocoa
import FlutterMacOS
import Vision

@main
class AppDelegate: FlutterAppDelegate {
  var statusItem: NSStatusItem?
  var trayChannel: FlutterMethodChannel?
  var notificationChannel: FlutterMethodChannel?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Note: Do NOT call super - FlutterAppDelegate doesn't implement this method
    
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      return
    }
    
    trayChannel = FlutterMethodChannel(name: "com.sehatlocker/system_tray", binaryMessenger: controller.engine.binaryMessenger)
    
    trayChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "initTray":
        self?.setupTray(arguments: call.arguments as? [String: Any])
        result(nil)
      case "updateTray":
        self?.updateTray(arguments: call.arguments as? [String: Any])
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    notificationChannel = FlutterMethodChannel(name: "com.sehatlocker/desktop_notifications", binaryMessenger: controller.engine.binaryMessenger)
    notificationChannel?.setMethodCallHandler { (call, result) in
      switch call.method {
      case "isDoNotDisturbEnabled":
        // Improved way to check DND on macOS
        let dndEnabled = CFPreferencesCopyAppValue("doNotDisturb" as CFString, "com.apple.notificationcenterui" as CFString) as? Bool ?? false
        result(dndEnabled)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let ocrChannel = FlutterMethodChannel(
      name: "com.sehatlocker/apple_vision_ocr",
      binaryMessenger: controller.engine.binaryMessenger
    )

    ocrChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "extractText":
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["imagePath"] as? String else {
          result(FlutterError(code: "bad_args", message: "Missing imagePath", details: nil))
          return
        }

        let url = URL(fileURLWithPath: imagePath)
        if !FileManager.default.fileExists(atPath: url.path) {
          result(FlutterError(code: "not_found", message: "Image not found", details: imagePath))
          return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
          let didAccess = url.startAccessingSecurityScopedResource()
          defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
          }
          
          let request = VNRecognizeTextRequest { req, err in
            if let err = err {
              DispatchQueue.main.async {
                result(FlutterError(code: "vision_error", message: err.localizedDescription, details: nil))
              }
              return
            }
            let observations = req.results as? [VNRecognizedTextObservation] ?? []
            let lines = observations.compactMap { obs in
              obs.topCandidates(1).first?.string
            }
            DispatchQueue.main.async {
              result(lines.joined(separator: "\n"))
            }
          }
          request.recognitionLevel = .accurate
          request.usesLanguageCorrection = true

          do {
            let handler = VNImageRequestHandler(url: url, options: [:])
            try handler.perform([request])
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "vision_error", message: error.localizedDescription, details: nil))
            }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func setupTray(arguments: [String: Any]?) {
    if statusItem == nil {
      statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
      statusItem?.button?.image = NSImage(named: NSImage.networkName) // Placeholder
      statusItem?.button?.image?.isTemplate = true
    }
    
    if let tooltip = arguments?["tooltip"] as? String {
      statusItem?.button?.toolTip = tooltip
    }
  }

  private func updateTray(arguments: [String: Any]?) {
    guard let statusItem = statusItem else { return }
    
    if let tooltip = arguments?["tooltip"] as? String {
      statusItem.button?.toolTip = tooltip
    }
    
    // Update Icon based on recording state
    if let recordingState = arguments?["recordingState"] as? String {
      switch recordingState {
      case "recording":
        statusItem.button?.image = NSImage(named: NSImage.touchBarRecordStartTemplateName)
      case "paused":
        statusItem.button?.image = NSImage(named: NSImage.touchBarPauseTemplateName)
      default:
        statusItem.button?.image = NSImage(named: NSImage.networkName)
      }
      statusItem.button?.image?.isTemplate = true
    }

    // Build Menu
    if let menuItems = arguments?["menuItems"] as? [[String: Any]] {
      let menu = NSMenu()
      for item in menuItems {
        if let type = item["type"] as? String, type == "separator" {
          menu.addItem(NSMenuItem.separator())
          continue
        }
        
        let label = item["label"] as? String ?? ""
        let id = item["id"] as? String ?? ""
        let enabled = item["enabled"] as? Bool ?? true
        
        let menuItem = NSMenuItem(title: label, action: #selector(menuItemClicked(_:)), keyEquivalent: "")
        menuItem.target = self
        menuItem.representedObject = id
        menuItem.isEnabled = enabled
        
        // Handle shortcuts if provided
        if let shortcut = item["shortcut"] as? String {
            if shortcut.contains("cmd+") {
                menuItem.keyEquivalent = String(shortcut.last!)
                menuItem.keyEquivalentModifierMask = .command
            }
        }
        
        menu.addItem(menuItem)
      }
      statusItem.menu = menu
    }
  }

  @objc func menuItemClicked(_ sender: NSMenuItem) {
    if let id = sender.representedObject as? String {
      if id == "quit" {
        NSApp.terminate(nil)
      } else {
        trayChannel?.invokeMethod("onTrayMenuItemClick", arguments: id)
      }
    }
  }
}
