//
//  ContentView.swift
//  BrowserHawk
//
//  Created by Vernon Wenberg on 8/15/26.
//

import SwiftUI

struct ContentView: View {
    // Persisted kiosk configuration.
    @AppStorage("kioskURL") private var kioskURL = "https://www.apple.com"
    @AppStorage("refreshInterval") private var refreshInterval = 120.0

    @StateObject private var controller = KioskController()
    @State private var showConfig = false

    var body: some View {
        KioskWebView(controller: controller) {
            showConfig = true
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            // Keep the screen awake for continuous kiosk display.
            UIApplication.shared.isIdleTimerDisabled = true
            controller.idleTimeout = refreshInterval
            controller.load(urlString: kioskURL)
        }
        .sheet(isPresented: $showConfig) {
            ConfigView(urlString: $kioskURL, refreshInterval: $refreshInterval) {
                // Apply the newly saved settings immediately.
                controller.idleTimeout = refreshInterval
                controller.load(urlString: kioskURL)
            }
        }
    }
}

#Preview {
    ContentView()
}
