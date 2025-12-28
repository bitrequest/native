import UIKit
import FirebaseCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:
        [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    // Handle Universal Links (e.g., https://bitrequest.github.io/...)
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let incomingURL = userActivity.webpageURL {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                webAppUrl = incomingURL.absoluteString
            }
            return true
        }
        return false
    }
    
    // Handle Custom URL Schemes (lndconnect:, eclair:, etc.)
    func application(_ app: UIApplication, open url: URL, options:
        [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let baseurl = "https://bitrequest.github.io?p=home&scheme="
        let string_url = "\(url)"
        
        if let divider = string_url.firstIndex(of: ":") {
            let scheme = string_url[...divider]
            if scheme == "lndconnect:" || scheme == "c-lightning-rest:" || scheme == "eclair:" || scheme == "acinq:" || scheme == "lnbits:" || scheme == "xmrrpc:" {
                if let encodedstring = string_url.data(using: .utf8)?.base64EncodedString() {
                    webAppUrl = baseurl + encodedstring
                } else {
                    webAppUrl = baseurl + "false"
                }
                return true
            }
        }
        return false
    }
}
