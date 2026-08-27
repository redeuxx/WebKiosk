//
//  ConfigView.swift
//  FocusKiosk
//
//  The hidden settings screen: edit the kiosk URL and the idle-refresh cycle.
//

import SwiftUI

struct ConfigView: View {
    @Binding var urlString: String
    @Binding var refreshInterval: Double
    @Binding var pin: String
    /// Non-nil when JAMF has pushed a HomepageURL via AppConfig; the field is shown as read-only.
    let managedURL: String?
    /// Non-nil when JAMF has pushed a RefreshCycle via AppConfig; the stepper is shown as read-only.
    let managedRefreshCycle: Double?
    /// Non-nil when JAMF has pushed a PIN via AppConfig; the PIN section is grayed out.
    let managedPIN: String?
    /// When true the Cancel button is hidden so the user must save a URL before proceeding.
    var isInitialSetup: Bool = false
    /// Called with the committed values when the user saves.
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    // Local working copies so edits only take effect on Save.
    @State private var draftURL: String = ""
    @State private var draftInterval: Double = 120
    @State private var newPIN: String = ""
    @State private var confirmPIN: String = ""
    @State private var showQRScanner = false

    /// Empty PIN fields mean "keep the current PIN".
    private var isChangingPIN: Bool {
        !newPIN.isEmpty || !confirmPIN.isEmpty
    }

    private var pinChangeIsValid: Bool {
        newPIN.count >= 4 && newPIN.allSatisfy(\.isNumber) && newPIN == confirmPIN
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let managedURL {
                        Label(managedURL, systemImage: "lock.fill")
                            .foregroundStyle(.secondary)
                    } else {
                        TextField("https://example.com", text: $draftURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .textContentType(.URL)
                        Button {
                            showQRScanner = true
                        } label: {
                            Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                        }
                    }
                } header: {
                    Text("Web Page")
                } footer: {
                    if managedURL != nil {
                        Text("URL is managed by your organization via JAMF.")
                    }
                }

                Section {
                    Stepper(value: $draftInterval, in: 10...3600, step: 10) {
                        Text("Refresh when idle for \(Int(draftInterval)) seconds")
                    }
                    .disabled(managedRefreshCycle != nil)
                } header: {
                    Text("Refresh Cycle")
                } footer: {
                    if managedRefreshCycle != nil {
                        Text("Refresh cycle is managed by your organization via JAMF.")
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(managedRefreshCycle != nil ? .secondary : .primary)

                Section {
                    SecureField("New PIN", text: $newPIN)
                        .keyboardType(.numberPad)
                        .disabled(managedPIN != nil)
                    SecureField("Confirm New PIN", text: $confirmPIN)
                        .keyboardType(.numberPad)
                        .disabled(managedPIN != nil)
                } header: {
                    Text("Change PIN")
                } footer: {
                    if managedPIN != nil {
                        Text("PIN is managed by your organization via JAMF.")
                            .foregroundStyle(.secondary)
                    } else if isChangingPIN && !pinChangeIsValid {
                        Text("PIN must be at least 4 digits and both fields must match.")
                            .foregroundStyle(.red)
                    } else {
                        Text("Leave blank to keep the current PIN.")
                    }
                }
                .foregroundStyle(managedPIN != nil ? .secondary : .primary)
            }
            .navigationTitle("Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isInitialSetup {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if managedURL == nil {
                            urlString = draftURL
                        }
                        if managedRefreshCycle == nil {
                            refreshInterval = draftInterval
                        }
                        if managedPIN == nil && isChangingPIN && pinChangeIsValid {
                            pin = newPIN
                        }
                        onSave()
                        dismiss()
                    }
                    .disabled((managedURL == nil && draftURL.trimmingCharacters(in: .whitespaces).isEmpty)
                              || (isChangingPIN && !pinChangeIsValid))
                }
            }
            .onAppear {
                draftURL = urlString
                draftInterval = managedRefreshCycle ?? refreshInterval
            }
            .sheet(isPresented: $showQRScanner) {
                NavigationStack {
                    QRScannerView { scanned in
                        draftURL = scanned.trimmingCharacters(in: .whitespacesAndNewlines)
                        showQRScanner = false
                    }
                    .ignoresSafeArea()
                    .navigationTitle("Scan QR Code")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showQRScanner = false }
                        }
                    }
                }
            }
        }
    }
}
