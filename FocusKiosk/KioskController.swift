//
//  KioskController.swift
//  FocusKiosk
//
//  Owns the web view, drives the idle-refresh timer, and locks navigation
//  to the configured page so the kiosk can't wander off.
//

import Combine
import WebKit

@MainActor
final class KioskController: NSObject, ObservableObject {
    /// The single web view instance shared with the SwiftUI layer.
    let webView: WKWebView

    /// Seconds of inactivity before the page is automatically reloaded.
    var idleTimeout: TimeInterval = 120

    /// True while the main frame is loading.
    @Published var isLoading = false
    /// Human-readable description of the last load failure, if any.
    @Published var loadError: String?

    private var idleTimer: Timer?
    private(set) var allowedURL: URL?

    override init() {
        let configuration = WKWebViewConfiguration()
        // Play media inline rather than kicking out to a full-screen player.
        configuration.allowsInlineMediaPlayback = true
        // Present as Mobile Safari: sites sniff the UA and show "outdated
        // browser" warnings for WKWebView's bare default. The OS/WebKit parts
        // of the UA are still supplied by the system automatically.
        configuration.applicationNameForUserAgent = "Version/26.0 Mobile/15E148 Safari/604.1"
        webView = WKWebView(frame: .zero, configuration: configuration)

        super.init()

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        // Kiosks shouldn't expose back/forward swipe navigation.
        webView.allowsBackForwardNavigationGestures = false
    }

    /// Loads the given address, remembers it as the only allowed page, and
    /// (re)starts the idle timer.
    func load(urlString: String) {
        guard let url = normalizedURL(from: urlString) else { return }
        allowedURL = url
        webView.load(URLRequest(url: url))
        resetIdleTimer()
    }

    /// Reloads the configured page from scratch.
    func reload() {
        if let url = allowedURL {
            webView.load(URLRequest(url: url))
        } else {
            webView.reload()
        }
    }

    /// Restarts the inactivity countdown. Called on every user touch.
    func resetIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: idleTimeout, repeats: false) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.reload()
            }
        }
    }

    /// Accepts bare hostnames by defaulting to https://.
    private func normalizedURL(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.contains("://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://\(trimmed)")
    }

    /// The registrable domain of the allowed URL (e.g. "paylocity.com"),
    /// used to keep navigation inside the configured site.
    private var allowedDomain: String? {
        guard let host = allowedURL?.host() else { return nil }
        let labels = host.split(separator: ".")
        guard labels.count >= 2 else { return host }
        return labels.suffix(2).joined(separator: ".")
    }

    private func isWithinAllowedSite(_ url: URL?) -> Bool {
        isAllowedHost(url?.host())
    }

    private func isAllowedHost(_ host: String?) -> Bool {
        guard let host = host?.lowercased(), let domain = allowedDomain else {
            return false
        }
        return host == domain || host.hasSuffix(".\(domain)")
    }
}

extension KioskController: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        // Auto-grant camera access to the configured site so unattended
        // kiosks never show a permission dialog a visitor could dismiss.
        // Microphone-involving requests are denied: the app declares no
        // microphone usage, and attempting capture without it would be
        // terminated by iOS.
        if type == .camera && isAllowedHost(origin.host) {
            decisionHandler(.grant)
        } else {
            decisionHandler(.deny)
        }
    }
}

extension KioskController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Sub-frame and resource loads are always allowed; only gate the
        // main frame so login flows and embedded content keep working.
        guard navigationAction.targetFrame?.isMainFrame ?? true else {
            decisionHandler(.allow)
            return
        }
        // Keep the kiosk inside the configured site: the page itself may
        // navigate freely within its own domain (logins, clock in/out),
        // but anything leaving the domain is blocked.
        if isWithinAllowedSite(navigationAction.request.url) {
            decisionHandler(.allow)
        } else {
            decisionHandler(navigationAction.navigationType == .other ? .allow : .cancel)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        loadError = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        isLoading = false
        loadError = error.localizedDescription
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        loadError = error.localizedDescription
    }

    /// The web content process can be killed by the system (e.g. memory
    /// pressure on a long-running kiosk); recover by reloading.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        reload()
    }
}
