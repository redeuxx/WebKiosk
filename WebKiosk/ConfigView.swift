//
//  ConfigView.swift
//  KioskLock
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

                Section("Refresh Cycle") {
                    Stepper(value: $draftInterval, in: 10...3600, step: 10) {
                        Text("Refresh when idle for \(Int(draftInterval)) seconds")
                    }
                }

                Section {
                    SecureField("New PIN", text: $newPIN)
                        .keyboardType(.numberPad)
                    SecureField("Confirm New PIN", text: $confirmPIN)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Change PIN")
                } footer: {
                    if isChangingPIN && !pinChangeIsValid {
                        Text("PIN must be at least 4 digits and both fields must match.")
                            .foregroundStyle(.red)
                    } else {
                        Text("Leave blank to keep the current PIN.")
                    }
                }
            }
            .navigationTitle("Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if managedURL == nil {
                            urlString = draftURL
                        }
                        refreshInterval = draftInterval
                        if isChangingPIN && pinChangeIsValid {
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
                draftInterval = refreshInterval
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
