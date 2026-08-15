//
//  PinEntryView.swift
//  BrowserHawk
//
//  PIN prompt shown before the configuration screen is revealed.
//

import SwiftUI

struct PinEntryView: View {
    /// The PIN that unlocks the configuration screen.
    let correctPIN: String
    /// Called when the correct PIN is entered.
    let onUnlock: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var enteredPIN = ""
    @State private var showError = false
    @FocusState private var pinFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)

                Text("Enter PIN to open Configuration")
                    .font(.headline)

                SecureField("PIN", text: $enteredPIN)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .frame(maxWidth: 200)
                    .padding(.vertical, 8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                    .focused($pinFieldFocused)
                    .onChange(of: enteredPIN) {
                        showError = false
                        // Unlock automatically once the full PIN is typed.
                        if enteredPIN == correctPIN {
                            onUnlock()
                        }
                    }

                if showError {
                    Text("Incorrect PIN")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }

                Button("Unlock") {
                    if enteredPIN == correctPIN {
                        onUnlock()
                    } else {
                        showError = true
                        enteredPIN = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(enteredPIN.isEmpty)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { pinFieldFocused = true }
        }
    }
}
