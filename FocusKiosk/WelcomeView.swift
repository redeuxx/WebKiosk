//
//  WelcomeView.swift
//  FocusKiosk
//
//  One-time first-launch screen: points the admin at the configuration
//  screen and explains how to reach it later.
//

import SwiftUI

struct WelcomeView: View {
    /// Opens the configuration screen directly.
    let onOpenConfig: () -> Void
    /// Dismisses without configuring.
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "globe.badge.chevron.backward")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("Welcome to FocusKiosk")
                .font(.largeTitle.bold())

            Text("FocusKiosk displays a single website in full screen - visitors can't navigate away from it.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 20) {
                Label {
                    Text("The app is currently showing a **default page**. Set your own URL in Configuration.")
                } icon: {
                    Image(systemName: "link")
                }
                Label {
                    Text("Open Configuration anytime by **pressing and holding with two fingers for 2 seconds**.")
                } icon: {
                    Image(systemName: "hand.tap")
                }
                Label {
                    Text("The default PIN is **0987** - change it in Configuration to keep visitors out.")
                } icon: {
                    Image(systemName: "lock")
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 460, alignment: .leading)

            Spacer()

            Button {
                onOpenConfig()
            } label: {
                Text("Open Configuration")
                    .frame(maxWidth: 460)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Not Now") {
                onSkip()
            }
        }
        .padding(32)
        .interactiveDismissDisabled()
    }
}
