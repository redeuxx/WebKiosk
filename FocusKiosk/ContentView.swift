//
//  ContentView.swift
//  FocusKiosk
//
//  Created by Vernon Wenberg on 8/15/26.
//

import SwiftUI

struct ContentView: View {
    // Persisted kiosk configuration.
    @AppStorage("kioskURL") private var kioskURL = ""
    @AppStorage("refreshInterval") private var refreshInterval = 120.0
    @AppStorage("configPIN") private var configPIN = "0987"
    @AppStorage("hasCompletedFirstLaunch") private var hasCompletedFirstLaunch = false

    /// The modal currently presented over the kiosk web view.
    private enum ActiveSheet: String, Identifiable {
        case welcome, pinEntry, config
        var id: String { rawValue }
    }

    @StateObject private var controller = KioskController()
    @StateObject private var managedConfig = ManagedConfigManager()
    @State private var activeSheet: ActiveSheet?

    private var effectiveURL: String {
        managedConfig.homepageURL ?? kioskURL
    }

    private var hasConfiguredURL: Bool {
        !effectiveURL.isEmpty
    }

    var body: some View {
        KioskWebView(controller: controller) {
            activeSheet = .pinEntry
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .overlay {
            if let error = controller.loadError {
                // Surface load failures instead of a blank screen.
                VStack(spacing: 16) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("Unable to Load Page")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        controller.reload()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(32)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            } else if controller.isLoading {
                ProgressView()
                    .controlSize(.large)
            }
        }
        .onAppear {
            // Keep the screen awake for continuous kiosk display.
            UIApplication.shared.isIdleTimerDisabled = true
            controller.idleTimeout = refreshInterval
            if hasConfiguredURL {
                controller.load(urlString: effectiveURL)
            }
            // Show welcome whenever no URL has been configured, not only on first launch.
            if !hasCompletedFirstLaunch || !hasConfiguredURL {
                // Present after a beat: a sheet triggered directly in onAppear
                // at launch can silently fail to appear.
                Task {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    if !hasCompletedFirstLaunch || !hasConfiguredURL {
                        activeSheet = .welcome
                    }
                }
            }
        }
        .onChange(of: managedConfig.homepageURL) { newURL in
            controller.load(urlString: newURL ?? kioskURL)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .welcome:
                WelcomeView {
                    hasCompletedFirstLaunch = true
                    activeSheet = .config
                }
            case .pinEntry:
                PinEntryView(correctPIN: configPIN) {
                    activeSheet = .config
                }
            case .config:
                ConfigView(urlString: $kioskURL,
                           refreshInterval: $refreshInterval,
                           pin: $configPIN,
                           managedURL: managedConfig.homepageURL,
                           isInitialSetup: !hasConfiguredURL) {
                    controller.idleTimeout = refreshInterval
                    controller.load(urlString: effectiveURL)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
