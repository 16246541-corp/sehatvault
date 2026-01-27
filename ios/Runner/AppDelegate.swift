import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let ocrChannel = FlutterMethodChannel(
        name: "com.sehatlocker/apple_vision_ocr",
        binaryMessenger: controller.binaryMessenger
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

          let request = VNRecognizeTextRequest { req, err in
            if let err = err {
              result(FlutterError(code: "vision_error", message: err.localizedDescription, details: nil))
              return
            }
            let observations = req.results as? [VNRecognizedTextObservation] ?? []
            let lines = observations.compactMap { obs in
              obs.topCandidates(1).first?.string
            }
            result(lines.joined(separator: "\n"))
          }
          request.recognitionLevel = .accurate
          request.usesLanguageCorrection = true

          do {
            let handler = VNImageRequestHandler(url: url, options: [:])
            try handler.perform([request])
          } catch {
            result(FlutterError(code: "vision_error", message: error.localizedDescription, details: nil))
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
