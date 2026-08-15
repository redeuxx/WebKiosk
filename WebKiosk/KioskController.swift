//
//  KioskController.swift
//  BrowserHawk
//
//  Owns the web view, drives the idle-refresh timer, and locks navigation
//  to the configured page so the kiosk can't wander off.
//

import WebKit

@MainActor
final class KioskController: NSObject, ObservableObject {
    /// The single web view instance shared with the SwiftUI layer.
    let webView: WKWebView

    /// Seconds of inactivity before the page is automatically reloaded.
    var idleTimeout: TimeInterval = 120

    private var idleTimer: Timer?
    private(set) var allowedURL: URL?

    override init() {
        let configuration = WKWebViewConfiguration()
        // Play media inline rather than kicking out to a full-screen player.
        configuration.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: configuration)

        super.init()

        webView.navigationDelegate = self
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
            Task { @MainActor in
                self?.reload()
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
}

extension KioskController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Block any navigation the user initiates by tapping a link or
        // submitting a form. Programmatic loads (our own reloads) and page
        // resources are still allowed through.
        switch navigationAction.navigationType {
        case .linkActivated, .formSubmitted, .formResubmitted, .backForward:
            decisionHandler(.cancel)
        default:
            decisionHandler(.allow)
        }
    }
}
