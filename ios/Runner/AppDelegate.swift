import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let channelName = "app.linkshare/share_intent"
    private var methodChannel: FlutterMethodChannel?
    private var sharedText: String?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController

        methodChannel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: controller.binaryMessenger
        )

        methodChannel?.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "getSharedText":
                result(self?.sharedText)
                self?.sharedText = nil
            case "getSharedImage":
                // iOS share extension not implemented yet — return nil.
                result(nil)
            case "openNotificationSettings":
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:]) { success in
                        result(success)
                    }
                } else {
                    result(FlutterError(
                        code: "SETTINGS_ERROR",
                        message: "Unable to open app settings",
                        details: nil
                    ))
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Handle deep links: linkshare://invite/{code}
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Store the URL as shared text for the Flutter side to pick up.
        sharedText = url.absoluteString
        methodChannel?.invokeMethod("onSharedText", arguments: sharedText)
        return true
    }
}
