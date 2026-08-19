//
//  ManagedConfigManager.swift
//  KioskLock
//
//  Reads MDM-managed configuration pushed by JAMF (or any AppConfig-compatible MDM).
//  JAMF delivers values via the standard "com.apple.configuration.managed" UserDefaults key.
//
//  AppConfig keys recognised by KioskLock:
//    HomepageURL  (String) - the URL the kiosk should display
//

import Combine
import Foundation

@MainActor
final class ManagedConfigManager: ObservableObject {

    // MARK: APPCONFIG KEYS

    private enum Key {
        static let managed = "com.apple.configuration.managed"
        static let homepageURL = "HomepageURL"
    }

    // MARK: PUBLISHED STATE

    /// Non-nil when JAMF has pushed a HomepageURL via AppConfig.
    @Published private(set) var homepageURL: String?

    // MARK: INIT

    private var observationTask: Task<Void, Never>?

    init() {
        refresh()
        // Task inherits the @MainActor context, so refresh() is safe to call directly.
        observationTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UserDefaults.didChangeNotification) {
                self?.refresh()
            }
        }
    }

    deinit {
        observationTask?.cancel()
    }

    // MARK: INTERNAL

    func refresh() {
        let managed = UserDefaults.standard.dictionary(forKey: Key.managed)
        homepageURL = managed?[Key.homepageURL] as? String
    }
}
