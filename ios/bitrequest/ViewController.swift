import WebKit
import Firebase
import FirebaseAnalytics

class ViewController: UIViewController {
    
    // MARK: Outlets
    @IBOutlet weak var webViewContainer: UIView!
    
    // MARK: Globals
    var webView: WKWebView!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupApp()
        setToolBar()
    }
    
    fileprivate func setToolBar() {
        let screenWidth = self.view.bounds.width
        let backButton = UIBarButtonItem(title: "◀", style: .plain, target: self, action: #selector(goBack))
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 44))
        toolBar.isTranslucent = false
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.items = [backButton]
        webView.addSubview(toolBar)
        // Constraints
        toolBar.bottomAnchor.constraint(equalTo: webView.bottomAnchor, constant: 0).isActive = true
        toolBar.leadingAnchor.constraint(equalTo: webView.leadingAnchor, constant: 0).isActive = true
        toolBar.trailingAnchor.constraint(equalTo: webView.trailingAnchor, constant: 0).isActive = true
        self.navigationItem.setHidesBackButton(true, animated:true);
    }
    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        } else {
        }
    }
    
    // Initialize WKWebView
    func setupWebView() {
        // set up webview
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: webViewContainer.frame.width, height: webViewContainer.frame.height))
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webViewContainer.addSubview(webView)
        // settings
        webView.allowsBackForwardNavigationGestures = true
        webView.configuration.preferences.javaScriptEnabled = true
        webView.customUserAgent = desktopUserAgent // set useragent to desktop to prevet OAuth returning '403 dissalowed useragent'
        webView.scrollView.bounces = false
    }
    
    // call after WebView has been initialized
    func setupUI() {
        // create callback for device entering Foreground
        let applicationDidBecomeActiveCallback : (Notification) -> Void = { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.openPage(pageUrl: webAppUrl)
            }
        }
        /// listen for device moving back to foreground
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main, using: applicationDidBecomeActiveCallback)
    }

    // load startpage
    func loadAppUrl() {
        let stringToUrl = URL(string: webAppUrl)
        let urlRequest = URLRequest(url: stringToUrl!)
        webView.load(urlRequest)
    }
    
    // Initialize App and start loading
    func setupApp() {
        setupWebView()
        setupUI()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { // Delay for webAppUrl variable to set
            self.loadAppUrl()
        }
    }
    
    // Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func initPage() {
        let initPageJS = """
            ios_init();
        """
        webView.evaluateJavaScript(initPageJS, completionHandler: nil)
    }
    
    func openPage(pageUrl: String) {
        //debugPrint(pageUrl);
        let openPageJS = """
            var url = "\(pageUrl)";
            ios_redirections(url);
        """
        webView.evaluateJavaScript(openPageJS, completionHandler: nil)
    }
}

// WebView Event Listeners
extension ViewController: WKNavigationDelegate {
}

// WebView additional handlers
extension ViewController: WKUIDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!){
        self.initPage()
    }
    
    // handle links opening in new tabs
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if (navigationAction.targetFrame == nil) {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    // restrict navigation to target host, open external links in 3rd party apps
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let requestUrl = navigationAction.request.url {
            let urlString = requestUrl.absoluteString
            let urlStringLower = urlString.lowercased()
            if (urlStringLower.hasPrefix("http")) {
                decisionHandler(.allow)
            }
            else {
                if (urlString.hasPrefix("data")) { // catch json backup downloads
                    if #available(iOS 14.5, *) {
                        decisionHandler(.download)
                    } else {
                        // Fallback on earlier versions
                    }
                }
                else {
                    UIApplication.shared.open(requestUrl, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                    decisionHandler(.cancel)
                }
                return
            }
        }
    }
    
    // Handle Dialogs
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler()
        }))
        self.present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        }))
        self.present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.text = defaultText
        }
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }

        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(nil)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
