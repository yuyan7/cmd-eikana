//
//  AppState.swift
//  ⌘英かな
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

class AppState {
    static let shared = AppState()

    private let stateLock = NSLock()

    private var activeApps: [AppData] = []
    private var excludedApps: [AppData] = []
    private var excludedAppNamesByBundleID: [String: String] = [:]

    private var shortcutMappingsByKeyCode: [CGKeyCode: [KeyMapping]] = [:]
    private var keyMappings: [KeyMapping] = []

    private weak var focusedKeyTextField: KeyTextField?

    let statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

    private init() {}

    private func withStateLock<T>(_ body: () -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return body()
    }

    private func withMainThread<T>(_ body: () -> T) -> T {
        if Thread.isMainThread {
            return body()
        }

        return DispatchQueue.main.sync(execute: body)
    }

    private func clone(_ appData: AppData) -> AppData {
        AppData(name: appData.name, id: appData.id)
    }

    private func clone(_ shortcut: KeyboardShortcut) -> KeyboardShortcut {
        KeyboardShortcut(keyCode: shortcut.keyCode, flags: shortcut.flags)
    }

    private func clone(_ mapping: KeyMapping) -> KeyMapping {
        KeyMapping(input: clone(mapping.input), output: clone(mapping.output), enable: mapping.enable)
    }

    private func rebuildShortcutMappingsLocked() {
        shortcutMappingsByKeyCode = [:]

        for mapping in keyMappings {
            let keyCode = mapping.input.keyCode

            if shortcutMappingsByKeyCode[keyCode] == nil {
                shortcutMappingsByKeyCode[keyCode] = []
            }

            shortcutMappingsByKeyCode[keyCode]?.append(mapping)

            #if DEBUG
                print("\(keyCode): \(mapping.input.toString()) => \(mapping.output.toString())")
            #endif
        }
    }

    private func rebuildExcludedAppNamesLocked() {
        excludedAppNamesByBundleID = [:]

        for app in excludedApps {
            excludedAppNamesByBundleID[app.id] = app.name
        }
    }

    func focusedKeyField() -> KeyTextField? {
        withMainThread {
            focusedKeyTextField
        }
    }

    func setFocusedKeyField(_ keyTextField: KeyTextField?) {
        withMainThread {
            focusedKeyTextField = keyTextField
        }
    }

    func clearFocusedKeyField(ifMatches keyTextField: KeyTextField? = nil) {
        withMainThread {
            if let keyTextField = keyTextField {
                if focusedKeyTextField == keyTextField {
                    focusedKeyTextField = nil
                }
                return
            }

            focusedKeyTextField = nil
        }
    }

    func updateFocusedKeyField(_ body: (KeyTextField) -> Void) {
        withMainThread {
            guard let keyTextField = focusedKeyTextField else {
                return
            }

            body(keyTextField)
        }
    }

    func blurFocusedKeyField() {
        withMainThread {
            focusedKeyTextField?.blur()
        }
    }

    func keyMappingCount() -> Int {
        withStateLock {
            keyMappings.count
        }
    }

    func keyMapping(at row: Int) -> KeyMapping? {
        withStateLock {
            guard keyMappings.indices.contains(row) else {
                return nil
            }

            return clone(keyMappings[row])
        }
    }

    func setInputShortcut(_ shortcut: KeyboardShortcut, at row: Int) {
        withStateLock {
            guard keyMappings.indices.contains(row) else {
                return
            }

            keyMappings[row].input = clone(shortcut)
            rebuildShortcutMappingsLocked()
        }
    }

    func setOutputShortcut(_ shortcut: KeyboardShortcut, at row: Int) {
        withStateLock {
            guard keyMappings.indices.contains(row) else {
                return
            }

            keyMappings[row].output = clone(shortcut)
            rebuildShortcutMappingsLocked()
        }
    }

    func addKeyMapping(_ keyMapping: KeyMapping) {
        withStateLock {
            keyMappings.append(clone(keyMapping))
            rebuildShortcutMappingsLocked()
        }
    }

    func setKeyMappings(_ newKeyMappings: [KeyMapping]) {
        withStateLock {
            keyMappings = newKeyMappings.map(clone)
            rebuildShortcutMappingsLocked()
        }
    }

    func swapKeyMappings(at lhs: Int, and rhs: Int) {
        withStateLock {
            guard keyMappings.indices.contains(lhs), keyMappings.indices.contains(rhs) else {
                return
            }

            keyMappings.swapAt(lhs, rhs)
            rebuildShortcutMappingsLocked()
        }
    }

    func moveKeyMapping(from row: Int, to destination: Int) {
        withStateLock {
            guard keyMappings.indices.contains(row) else {
                return
            }

            let boundedDestination = min(max(destination, 0), keyMappings.count - 1)
            let keyMapping = keyMappings.remove(at: row)
            keyMappings.insert(keyMapping, at: boundedDestination)
            rebuildShortcutMappingsLocked()
        }
    }

    func removeKeyMapping(at row: Int) {
        withStateLock {
            guard keyMappings.indices.contains(row) else {
                return
            }

            keyMappings.remove(at: row)
            rebuildShortcutMappingsLocked()
        }
    }

    func shortcutMappings(for keyCode: CGKeyCode) -> [KeyMapping]? {
        withStateLock {
            shortcutMappingsByKeyCode[keyCode]?.map(clone)
        }
    }

    func saveKeyMappings() {
        let mappings = withStateLock {
            keyMappings.map { $0.toDictionary() }
        }

        UserDefaults.standard.set(mappings, forKey: "mappings")
    }

    func addExcludedApp(_ appData: AppData) {
        withStateLock {
            excludedApps.append(clone(appData))
            rebuildExcludedAppNamesLocked()
        }
    }

    func combinedAppCount() -> Int {
        withStateLock {
            excludedApps.count + activeApps.count
        }
    }

    func combinedApp(at row: Int) -> (isExcluded: Bool, app: AppData)? {
        withStateLock {
            if excludedApps.indices.contains(row) {
                return (true, clone(excludedApps[row]))
            }

            let activeRow = row - excludedApps.count
            guard activeApps.indices.contains(activeRow) else {
                return nil
            }

            return (false, clone(activeApps[activeRow]))
        }
    }

    func toggleExcludedApp(at row: Int) {
        withStateLock {
            if excludedApps.indices.contains(row) {
                let app = excludedApps.remove(at: row)
                activeApps.insert(app, at: 0)
            } else {
                let activeRow = row - excludedApps.count
                guard activeApps.indices.contains(activeRow) else {
                    return
                }

                let app = activeApps.remove(at: activeRow)
                excludedApps.append(app)
            }

            rebuildExcludedAppNamesLocked()
        }
    }

    func handleActivatedApp(name: String, id: String, currentBundleId: String) -> Bool {
        withStateLock {
            let isExcluded = excludedAppNamesByBundleID[id] != nil
            if id == currentBundleId || isExcluded {
                return isExcluded
            }

            activeApps.removeAll { $0.id == id }
            activeApps.insert(AppData(name: name, id: id), at: 0)

            if activeApps.count > 10 {
                activeApps.removeLast()
            }

            return false
        }
    }

    func saveExcludedApps() {
        let apps = withStateLock {
            excludedApps.map { $0.toDictionary() }
        }

        UserDefaults.standard.set(apps, forKey: "exclusionApps")
    }

    func configureStatusItem(title: String, menu: NSMenu) {
        statusItem.menu = menu

        if let button = statusItem.button {
            button.title = title
            if let cell = button.cell as? NSButtonCell {
                cell.highlightsBy = .pushInCellMask
            }
        }
    }

    func setStatusItemVisible(_ isVisible: Bool) {
        statusItem.isVisible = isVisible
    }
}
