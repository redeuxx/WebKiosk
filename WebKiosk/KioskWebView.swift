//
//  KioskWebView.swift
//  KioskLock
//
//  Bridges the WKWebView into SwiftUI and wires up the touch recognizers that
//  reset the idle timer and reveal the hidden configuration screen.
//

import SwiftUI
import WebKit

struct KioskWebView: UIViewRepresentable {
    let controller: KioskController
    /// Invoked when the user performs the two-finger long press.
    let onRevealConfig: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller, onRevealConfig: onRevealConfig)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = controller.webView

        // Fires on every touch so we can keep the idle timer alive.
        let anyTouch = AnyTouchGestureRecognizer(target: context.coordinator,
                                                 action: #selector(Coordinator.handleTouch))
        anyTouch.delegate = context.coordinator
        webView.addGestureRecognizer(anyTouch)

        // Two fingers held for two seconds opens the configuration screen.
        let revealConfig = UILongPressGestureRecognizer(target: context.coordinator,
                                                         action: #selector(Coordinator.handleConfigGesture))
        revealConfig.numberOfTouchesRequired = 2
        revealConfig.minimumPressDuration = 2.0
        revealConfig.delegate = context.coordinator
        webView.addGestureRecognizer(revealConfig)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.onRevealConfig = onRevealConfig
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let controller: KioskController
        var onRevealConfig: () -> Void

        init(controller: KioskController, onRevealConfig: @escaping () -> Void) {
            self.controller = controller
            self.onRevealConfig = onRevealConfig
        }

        @objc func handleTouch() {
            controller.resetIdleTimer()
        }

        @objc func handleConfigGesture(_ recognizer: UILongPressGestureRecognizer) {
            if recognizer.state == .began {
                onRevealConfig()
            }
        }

        // Our recognizers observe touches; they must never steal them from the
        // web content or from each other.
        nonisolated func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

/// A recognizer that reports every touch without interfering with the view's
/// own gesture handling.
final class AnyTouchGestureRecognizer: UIGestureRecognizer {
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        state = .began
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        state = .ended
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        state = .cancelled
    }
}
