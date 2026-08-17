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
    guard call.method == "recognizeText" || call.method == "detectDocument" || call.method == "scanBarcode" else {
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
      if call.method == "detectDocument" {
        self.detectDocument(cgImage: cgImage, result: result)
        return
      }
      if call.method == "scanBarcode" {
        self.scanBarcode(cgImage: cgImage, result: result)
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
      if let languages = args["languages"] as? [String], !languages.isEmpty {
        let supported = try? request.supportedRecognitionLanguages()
        request.recognitionLanguages = languages.filter { supported?.contains($0) == true }
      }
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

  private func scanBarcode(cgImage: CGImage, result: @escaping FlutterResult) {
    let request = VNDetectBarcodesRequest { request, error in
      if let error = error {
        DispatchQueue.main.async {
          result(FlutterError(code: "barcode_failed", message: error.localizedDescription, details: nil))
        }
        return
      }
      let value = (request.results as? [VNBarcodeObservation])?
        .compactMap { $0.payloadStringValue?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .first { !$0.isEmpty }
      DispatchQueue.main.async { result(value) }
    }
    request.symbologies = [.qr]
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
      try handler.perform([request])
    } catch {
      DispatchQueue.main.async {
        result(FlutterError(code: "barcode_failed", message: error.localizedDescription, details: nil))
      }
    }
  }

  private func detectDocument(cgImage: CGImage, result: @escaping FlutterResult) {
    let request = VNDetectRectanglesRequest { request, error in
      if let error = error {
        DispatchQueue.main.async {
          result(FlutterError(code: "detection_failed", message: error.localizedDescription, details: nil))
        }
        return
      }
      guard let rectangle = (request.results as? [VNRectangleObservation])?.first else {
        DispatchQueue.main.async { result(nil) }
        return
      }
      // Vision uses a lower-left origin; Flutter's image crop uses upper-left.
      let points: [Double] = [
        rectangle.topLeft.x, 1 - rectangle.topLeft.y,
        rectangle.topRight.x, 1 - rectangle.topRight.y,
        rectangle.bottomRight.x, 1 - rectangle.bottomRight.y,
        rectangle.bottomLeft.x, 1 - rectangle.bottomLeft.y,
      ]
      DispatchQueue.main.async { result(points) }
    }
    request.maximumObservations = 1
    request.minimumConfidence = 0.65
    request.minimumAspectRatio = 0.2
    request.quadratureTolerance = 30
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
      try handler.perform([request])
    } catch {
      DispatchQueue.main.async {
        result(FlutterError(code: "detection_failed", message: error.localizedDescription, details: nil))
      }
    }
  }
}
