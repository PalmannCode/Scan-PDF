import Flutter
import UIKit
import Vision

/// On-device text recognition backed by Apple's Vision framework
/// (VNRecognizeTextRequest). Replaces Google ML Kit: no binary pods,
/// works on both device and simulator, nothing leaves the phone.
public class OcrPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "scanpdf/ocr", binaryMessenger: registrar.messenger())
    let instance = OcrPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "recognizeText" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let args = call.arguments as? [String: Any],
          let path = args["path"] as? String else {
      result(FlutterError(
        code: "bad_args", message: "Expected {path: String}", details: nil))
      return
    }
    DispatchQueue.global(qos: .userInitiated).async {
      guard let image = UIImage(contentsOfFile: path),
            let cgImage = image.cgImage else {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "decode_failed",
            message: "Could not read image at \(path)", details: nil))
        }
        return
      }
      let request = VNRecognizeTextRequest { request, error in
        if let error = error {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "ocr_failed",
              message: error.localizedDescription, details: nil))
          }
          return
        }
        let observations =
          request.results as? [VNRecognizedTextObservation] ?? []
        let text = observations
          .compactMap { $0.topCandidates(1).first?.string }
          .joined(separator: "\n")
        DispatchQueue.main.async { result(text) }
      }
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true
      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      do {
        try handler.perform([request])
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "ocr_failed",
            message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}
