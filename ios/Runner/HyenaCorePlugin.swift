import Flutter
import HyenaCore

/// MethodChannel → gomobile `Mobile*`（与 Android `HyenaCorePlugin.kt` 方法名一致）
public class HyenaCorePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.hyena/core",
      binaryMessenger: registrar.messenger())
    let instance = HyenaCorePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setup":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "BAD_ARGS", message: nil, details: nil))
        return
      }
      let opt = MobileSetupOptions()
      opt.basePath = (args["basePath"] as? String) ?? ""
      opt.workingDir = (args["workingDir"] as? String) ?? ""
      opt.tempDir = (args["tempDir"] as? String) ?? ""
      opt.listen = (args["listen"] as? String) ?? ""
      opt.secret = (args["secret"] as? String) ?? ""
      opt.mode = (args["mode"] as? Int) ?? 0
      opt.debug = (args["debug"] as? Bool) ?? false
      opt.fixAndroidStack = false
      var error: NSError?
      let ok = MobileSetup(opt, nil, &error)
      if !ok {
        result(FlutterError(code: "SETUP_FAILED", message: error?.localizedDescription, details: nil))
      } else {
        result(nil)
      }
    case "start":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "BAD_ARGS", message: nil, details: nil))
        return
      }
      let configPath = (args["configPath"] as? String) ?? ""
      let configContent = (args["configContent"] as? String) ?? ""
      var error: NSError?
      let ok = MobileStart(configPath, configContent, &error)
      if !ok {
        result(FlutterError(code: "START_FAILED", message: error?.localizedDescription, details: nil))
      } else {
        result(nil)
      }
    case "stop":
      var error: NSError?
      let ok = MobileStop(&error)
      if !ok {
        result(FlutterError(code: "STOP_FAILED", message: error?.localizedDescription, details: nil))
      } else {
        result(nil)
      }
    case "pause":
      MobilePause()
      result(nil)
    case "wake":
      MobileWake()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
