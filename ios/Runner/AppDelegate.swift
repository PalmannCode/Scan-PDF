import Flutter
import PDFKit
import UIKit
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OcrPlugin") {
      OcrPlugin.register(with: registrar)
    }
    if let iconRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppIconPlugin") {
      let iconChannel = FlutterMethodChannel(
        name: "scanpdf/app_icon", binaryMessenger: iconRegistrar.messenger())
      iconChannel.setMethodCallHandler { call, result in
        guard call.method == "setAlternateIcon" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard UIApplication.shared.supportsAlternateIcons else {
          result(FlutterError(code: "unsupported", message: "Alternate icons are not supported on this device.", details: nil))
          return
        }
        let iconName = (call.arguments as? [String: Any])?["name"] as? String
        UIApplication.shared.setAlternateIconName(iconName?.isEmpty == true ? nil : iconName) { error in
          if let error = error {
            result(FlutterError(code: "icon_change_failed", message: error.localizedDescription, details: nil))
          } else {
            result(nil)
          }
        }
      }
    }
    if let pdfRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "PdfSecurityPlugin") {
      let pdfChannel = FlutterMethodChannel(
        name: "scanpdf/pdf_security", binaryMessenger: pdfRegistrar.messenger())
      pdfChannel.setMethodCallHandler { call, result in
        guard call.method == "protect",
          let args = call.arguments as? [String: Any],
          let source = args["source"] as? String,
          let output = args["output"] as? String,
          let password = args["password"] as? String,
          !password.isEmpty
        else {
          result(FlutterError(code: "invalid_arguments", message: "A source, output, and password are required.", details: nil))
          return
        }
        guard let document = PDFDocument(url: URL(fileURLWithPath: source)) else {
          result(FlutterError(code: "invalid_pdf", message: "The PDF could not be opened.", details: nil))
          return
        }
        let options: [PDFDocumentWriteOption: Any] = [
          .userPasswordOption: password,
          .ownerPasswordOption: UUID().uuidString,
        ]
        let outputURL = URL(fileURLWithPath: output)
        do {
          try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true)
          guard document.write(to: outputURL, withOptions: options) else {
            result(FlutterError(code: "write_failed", message: "The protected PDF could not be written.", details: nil))
            return
          }
          result(output)
        } catch {
          result(FlutterError(code: "write_failed", message: error.localizedDescription, details: nil))
        }
      }
    }
    if let storefrontRegistrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "HomeScreenApiStorefrontPlugin"
    ) {
      let storefrontChannel = FlutterMethodChannel(
        name: "home_screen_api/storefront", binaryMessenger: storefrontRegistrar.messenger())
      storefrontChannel.setMethodCallHandler { call, result in
        guard call.method == "getStorefrontCountry" else {
          result(FlutterMethodNotImplemented)
          return
        }
        if #available(iOS 15.0, *) {
          Task {
            let countryCode = await Storefront.current?.countryCode
            await MainActor.run {
              result(countryCode)
            }
          }
        } else {
          result(SKPaymentQueue.default().storefront?.countryCode)
        }
      }
    }
  }
}
