import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:
        [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    func handleIncomingDynamicLink(_ dynamicLink: DynamicLink) {
        guard let url = dynamicLink.url else {
            return
        }
        let deeplink = url.absoluteString
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { // Small Delay to overwrite webAppUrl.
            webAppUrl = deeplink
        }
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let incomingURL = userActivity.webpageURL {
           let linkHandled = DynamicLinks.dynamicLinks().handleUniversalLink(incomingURL)
                { (DynamicLink, error) in
                    guard error == nil else {
                    return
                }
                if let dynamicLink = DynamicLink {
                    self.handleIncomingDynamicLink(dynamicLink)
                }
            }
            if linkHandled {
                return true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    webAppUrl = incomingURL.absoluteString
                }
                return false
            }
        }
        return false
    }
    
    func application(_ app: UIApplication, open url: URL, options:
        [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
            self.handleIncomingDynamicLink(dynamicLink)
            return true
        } else {
            let baseurl = "https://bitrequest.github.io?p=home&scheme=";
            let string_url = "\(url)";
            let divider = string_url.firstIndex(of: ":")!
            let scheme = string_url[...divider];
            if (scheme == "lndconnect:" || scheme == "c-lightning-rest:" || scheme == "eclair:" || scheme == "acinq:" || scheme == "lnbits:") {
                let encodedstring = string_url.data(using: .utf8)?.base64EncodedString();
                if (encodedstring != nil) {
                    webAppUrl = baseurl + encodedstring!;
                }
                else {
                    webAppUrl = baseurl + "false";
                }
            }
            return false
        }
    }
}
