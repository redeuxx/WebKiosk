//
//  ConfigView.swift
//  BrowserHawk
//
//  The hidden settings screen: edit the kiosk URL and the idle-refresh cycle.
//

import SwiftUI

struct ConfigView: View {
    @Binding var urlString: String
    @Binding var refreshInterval: Double

    /// Called with the committed values when the user saves.
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    // Local working copies so edits only take effect on Save.
    @State private var draftURL: String = ""
    @State private var draftInterval: Double = 120

    var body: some View {
        NavigationStack {
            Form {
                Section("Web Page") {
                    TextField("https://example.com", text: $draftURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .textContentType(.URL)
                }

                Section("Refresh Cycle") {
                    Stepper(value: $draftInterval, in: 10...3600, step: 10) {
                        Text("Refresh when idle for \(Int(draftInterval)) seconds")
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
                        urlString = draftURL
                        refreshInterval = draftInterval
                        onSave()
                        dismiss()
                    }
                    .disabled(draftURL.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                draftURL = urlString
                draftInterval = refreshInterval
            }
        }
    }
}
