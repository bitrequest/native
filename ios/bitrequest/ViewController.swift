import UIKit
import WebKit
import FirebaseAnalytics

class ViewController: UIViewController {
    
    // MARK: Outlets
    @IBOutlet weak var webViewContainer: UIView!
    
    // MARK: Globals
    var webView: WKWebView!
    var activeDownload: WKDownload?
   
    override func viewDidLoad() {
        super.viewDidLoad()
        setupApp()
        setToolBar()
        // webView.isInspectable = true // Uncomment for debugging
    }
    
    fileprivate func setToolBar() {
        let backButton = UIBarButtonItem(title: "◀", style: .plain, target: self, action: #selector(goBack))
        let toolBar = UIToolbar()
        toolBar.isTranslucent = false
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.items = [backButton]
        webView.addSubview(toolBar)
        
        NSLayoutConstraint.activate([
            toolBar.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            toolBar.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        
        self.navigationItem.setHidesBackButton(true, animated: true)
    }
    
    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        
        webView = WKWebView(frame: webViewContainer.bounds, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webViewContainer.addSubview(webView)
        
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = desktopUserAgent // Prevent OAuth '403 disallowed useragent'
        webView.scrollView.bounces = false
    }
    
    func setupUI() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func applicationDidBecomeActive() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.openPage(pageUrl: webAppUrl)
        }
    }

    func loadAppUrl() {
        guard let url = URL(string: webAppUrl) else {
            print("Invalid URL: \(webAppUrl)")
            return
        }
        webView.load(URLRequest(url: url))
    }
    
    func setupApp() {
        setupWebView()
        setupUI()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.loadAppUrl()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func initPage() {
        webView.evaluateJavaScript("ios_init();")
    }
    
    func openPage(pageUrl: String) {
        Analytics.logEvent("app_opened", parameters: ["page": pageUrl])
        let escapedUrl = pageUrl.replacingOccurrences(of: "\"", with: "\\\"")
        webView.evaluateJavaScript("ios_redirections(\"\(escapedUrl)\");")
    }
}

// MARK: - WKNavigationDelegate
extension ViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let requestUrl = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        let urlString = requestUrl.absoluteString
        
        if urlString.lowercased().hasPrefix("http") {
            decisionHandler(.allow)
        } else if urlString.hasPrefix("data:") {
            // Handle data: URLs (e.g., JSON backup downloads)
            decisionHandler(.download)
        } else {
            // Open external URLs (mailto:, tel:, etc.) in system apps
            UIApplication.shared.open(requestUrl, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }
    
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }
}

// MARK: - WKDownloadDelegate
extension ViewController: WKDownloadDelegate {
    
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let tempDir = FileManager.default.temporaryDirectory
        let fileUrl = tempDir.appendingPathComponent(suggestedFilename)
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: fileUrl)
        
        self.activeDownload = download
        completionHandler(fileUrl)
    }
    
    func downloadDidFinish(_ download: WKDownload) {
        guard let url = download.progress.fileURL else { return }
        
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            // iPad requires sourceView
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            }
            
            self.present(activityVC, animated: true)
        }
        
        self.activeDownload = nil
    }
    
    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        print("Download failed: \(error.localizedDescription)")
        self.activeDownload = nil
    }
}

// MARK: - WKUIDelegate
extension ViewController: WKUIDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.initPage()
    }
    
    // Handle links opening in new tabs
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    // MARK: JavaScript Dialogs
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(nil)
        })
        present(alert, animated: true)
    }
}
