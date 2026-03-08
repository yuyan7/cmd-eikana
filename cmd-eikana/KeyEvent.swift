//
//  KeyEvent.swift
//  ⌘英かな
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

class KeyEvent: NSObject {
    var keyCode: CGKeyCode? = nil
    var isExclusionApp = false
    let bundleId: String = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    var hasConvertedEventLog: KeyMapping? = nil
    var eventTap: CFMachPort?
    var permissionTimer: Timer?
    var hasShownPermissionAlert = false
    var isWatching = false
    var runLoopSource: CFRunLoopSource?
    var tapReenableCount = 0
    let maxTapReenableCount = 10
    var lastTapDisableTime: Date?
    let stateLock = NSLock()

    override init() {
        super.init()
    }

    func setKeyCode(_ keyCode: CGKeyCode?) {
        stateLock.lock()
        self.keyCode = keyCode
        stateLock.unlock()
    }

    func currentKeyCode() -> CGKeyCode? {
        stateLock.lock()
        let keyCode = self.keyCode
        stateLock.unlock()
        return keyCode
    }

    func setIsExclusionApp(_ isExclusionApp: Bool) {
        stateLock.lock()
        self.isExclusionApp = isExclusionApp
        stateLock.unlock()
    }

    func currentIsExclusionApp() -> Bool {
        stateLock.lock()
        let isExclusionApp = self.isExclusionApp
        stateLock.unlock()
        return isExclusionApp
    }

    func updateTapReenableState(for eventTap: CFMachPort) {
        stateLock.lock()
        defer { stateLock.unlock() }

        let now = Date()
        if let lastTime = lastTapDisableTime, now.timeIntervalSince(lastTime) > 60 {
            tapReenableCount = 0
        }
        lastTapDisableTime = now

        if tapReenableCount < maxTapReenableCount {
            tapReenableCount += 1
            print("Event tap disabled, re-enabling... (attempt \(tapReenableCount)/\(maxTapReenableCount))")
            CGEvent.tapEnable(tap: eventTap, enable: true)
        } else {
            print("Event tap re-enable limit reached (\(maxTapReenableCount) attempts). Stopping retries.")
        }
    }

    func activeKeyTextField() -> KeyTextField? {
        AppState.shared.focusedKeyField()
    }

    func hasActiveKeyTextField() -> Bool {
        AppState.shared.focusedKeyField() != nil
    }

    func updateActiveKeyTextField(_ body: (KeyTextField) -> Void) {
        AppState.shared.updateFocusedKeyField(body)
    }

    func shortcutMappings(for keyCode: CGKeyCode) -> [KeyMapping]? {
        AppState.shared.shortcutMappings(for: keyCode)
    }
    
    func start() {
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                            selector: #selector(KeyEvent.setActiveApp(_:)),
                                                            name: NSWorkspace.didActivateApplicationNotification,
                                                            object:nil)

        if ensurePermissions(prompt: true) {
            watch()
        } else {
            startPermissionTimer()
        }
    }

    func ensurePermissions(prompt: Bool) -> Bool {
        let hasInputMonitoring = requestInputMonitoringAccess(prompt: prompt)
        let hasPostEventAccess = requestPostEventAccess(prompt: prompt)
        let hasAccessibilityAccess = requestAccessibilityAccess(prompt: prompt)

        if !hasInputMonitoring || !hasPostEventAccess || !hasAccessibilityAccess {
            if prompt {
                showPermissionAlert(inputMonitoring: hasInputMonitoring,
                                    postEventAccess: hasPostEventAccess,
                                    accessibility: hasAccessibilityAccess)
            }
            return false
        }

        hasShownPermissionAlert = false
        return true
    }

    func requestInputMonitoringAccess(prompt: Bool) -> Bool {
        if CGPreflightListenEventAccess() {
            return true
        }

        if prompt {
            _ = CGRequestListenEventAccess()
        }

        return false
    }

    func requestPostEventAccess(prompt: Bool) -> Bool {
        if CGPreflightPostEventAccess() {
            return true
        }

        if prompt {
            _ = CGRequestPostEventAccess()
        }

        return false
    }

    func requestAccessibilityAccess(prompt: Bool) -> Bool {
        if prompt {
            let checkOptionPrompt = kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString
            let options: CFDictionary = [checkOptionPrompt: true] as NSDictionary
            return AXIsProcessTrustedWithOptions(options)
        }

        return AXIsProcessTrusted()
    }

    func startPermissionTimer() {
        if permissionTimer != nil {
            return
        }

        permissionTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                               target: self,
                                               selector: #selector(KeyEvent.watchPermissions(_:)),
                                               userInfo: nil,
                                               repeats: true)
    }

    @objc func watchPermissions(_ timer: Timer) {
        if ensurePermissions(prompt: false) {
            timer.invalidate()
            permissionTimer = nil
            watch()
        }
    }

    func showPermissionAlert(inputMonitoring: Bool,
                             postEventAccess: Bool,
                             accessibility: Bool) {
        if hasShownPermissionAlert {
            return
        }

        hasShownPermissionAlert = true

        var missingPermissions: [String] = []

        if !inputMonitoring {
            missingPermissions.append("- 入力監視を許可してください")
        }

        if !postEventAccess {
            missingPermissions.append("- キーボード操作を送出するための監視権限を許可してください")
        }

        if !accessibility {
            missingPermissions.append("- アクセシビリティを許可してください")
        }

        let alert = NSAlert()
        alert.messageText = "⌘英かなの権限設定が必要です"
        alert.informativeText = "⌘英かなを使うには次の権限が必要です。\n\n"
            + missingPermissions.joined(separator: "\n")
            + "\n\nシステム設定 > プライバシーとセキュリティ で許可したあと、自動で再開します。"
        alert.addButton(withTitle: "システム設定を開く")
        alert.addButton(withTitle: "あとで")

        if alert.runModal() == .alertFirstButtonReturn {
            openPrivacySettings(inputMonitoring: inputMonitoring,
                                postEventAccess: postEventAccess,
                                accessibility: accessibility)
        }
    }

    func openPrivacySettings(inputMonitoring: Bool,
                             postEventAccess: Bool,
                             accessibility: Bool) {
        let privacyPaneURL: String

        if !inputMonitoring {
            privacyPaneURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        } else if !postEventAccess {
            privacyPaneURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_PostEvent"
        } else {
            privacyPaneURL = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        }

        if let url = URL(string: privacyPaneURL), NSWorkspace.shared.open(url) {
            return
        }

        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }
    
    @objc func setActiveApp(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let app = userInfo["NSWorkspaceApplicationKey"] as? NSRunningApplication else {
            return
        }
        
        if let name = app.localizedName, let id = app.bundleIdentifier {
            setIsExclusionApp(AppState.shared.handleActivatedApp(name: name, id: id, currentBundleId: bundleId))
            
        }
    }
    
    func watch() {
        if isWatching {
            return
        }

        isWatching = true

        // マウスのドラッグバグ回避のため、NSEventとCGEventを併用
        // CGEventのみでやる方法を捜索中
        let nsEventMaskList: NSEvent.EventTypeMask = [
            .leftMouseDown,
            .leftMouseUp,
            .rightMouseDown,
            .rightMouseUp,
            .otherMouseDown,
            .otherMouseUp,
            .scrollWheel
        ]
        
        NSEvent.addGlobalMonitorForEvents(matching: nsEventMaskList) {(event: NSEvent) -> Void in
            self.setKeyCode(nil)
        }
        
        NSEvent.addLocalMonitorForEvents(matching: nsEventMaskList) {(event: NSEvent) -> NSEvent? in
            self.setKeyCode(nil)
            return event
        }
        
        let eventMaskList = [
            CGEventType.keyDown.rawValue,
            CGEventType.keyUp.rawValue,
            CGEventType.flagsChanged.rawValue,
//            CGEventType.leftMouseDown.rawValue,
//            CGEventType.leftMouseUp.rawValue,
//            CGEventType.rightMouseDown.rawValue,
//            CGEventType.rightMouseUp.rawValue,
//            CGEventType.otherMouseDown.rawValue,
//            CGEventType.otherMouseUp.rawValue,
//            CGEventType.scrollWheel.rawValue,
            UInt32(NX_SYSDEFINED) // Media key Event
        ]
        var eventMask: UInt32 = 0
        
        for mask in eventMaskList {
            eventMask |= (1 << mask)
        }
        
        let observer = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? in
                if let observer = refcon {
                    let mySelf = Unmanaged<KeyEvent>.fromOpaque(observer).takeUnretainedValue()
                    return mySelf.eventCallback(proxy: proxy, type: type, event: event)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: observer
            ) else {
                print("failed to create event tap")
                exit(1)
        }

        self.eventTap = eventTap
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let runLoopSource = self.runLoopSource else { return }
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
            CFRunLoopRun()
        }
    }
    
    func eventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap = eventTap {
                updateTapReenableState(for: eventTap)
            }
            return Unmanaged.passUnretained(event)
        }

        if currentIsExclusionApp() {
            return Unmanaged.passUnretained(event)
        }
        
        if let mediaKeyEvent = MediaKeyEvent(event) {
            return mediaKeyEvent.keyDown ? mediaKeyDown(mediaKeyEvent) : mediaKeyUp(mediaKeyEvent)
        }
        
        switch type {
        case CGEventType.flagsChanged:
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            
            if modifierMasks[keyCode] == nil {
                return Unmanaged.passUnretained(event)
            }
            return event.flags.rawValue & modifierMasks[keyCode]!.rawValue != 0 ?
                modifierKeyDown(event) : modifierKeyUp(event)
        
        case CGEventType.keyDown:
            return keyDown(event)
        
        case CGEventType.keyUp:
            return keyUp(event)
        
        default:
            setKeyCode(nil)
            
            return Unmanaged.passUnretained(event)
        }
    }
    
    func keyDown(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        #if DEBUG
            // print("keyCode: \(KeyboardShortcut(event).keyCode)")
             print(KeyboardShortcut(event).toString())
        #endif
        
        setKeyCode(nil)
      
        if activeKeyTextField() != nil {
            updateActiveKeyTextField { keyTextField in
                keyTextField.shortcut = KeyboardShortcut(event)
                keyTextField.stringValue = keyTextField.shortcut!.toString()
            }

            return nil
        }
        
        if hasConvertedEvent(event) {
            if let event = getConvertedEvent(event) {
                return Unmanaged.passUnretained(event)
            }
            return nil
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    func keyUp(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        setKeyCode(nil)
        
        if hasConvertedEvent(event) {
            if let event = getConvertedEvent(event) {
                return Unmanaged.passUnretained(event)
            }
            return nil
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    func modifierKeyDown(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        #if DEBUG
            print(KeyboardShortcut(event).toString())
        #endif

        setKeyCode(CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode)))
        
        if activeKeyTextField() != nil {
            updateActiveKeyTextField { keyTextField in
                guard keyTextField.isAllowModifierOnly else {
                    return
                }

                let shortcut = KeyboardShortcut(event)
                keyTextField.shortcut = shortcut
                keyTextField.stringValue = shortcut.toString()
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    func modifierKeyUp(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        if hasActiveKeyTextField() {
            setKeyCode(nil)
        }
        else if currentKeyCode() == CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode)) {
            if let convertedEvent = getConvertedEvent(event) {
                KeyboardShortcut(convertedEvent).postEvent()
            }
        }
        
        setKeyCode(nil)
        
        return Unmanaged.passUnretained(event)
    }
    
    func mediaKeyDown(_ mediaKeyEvent: MediaKeyEvent) -> Unmanaged<CGEvent>? {
        #if DEBUG
            print(KeyboardShortcut(keyCode: CGKeyCode(1000 + mediaKeyEvent.keyCode), flags: mediaKeyEvent.flags).toString())
        #endif
        
        setKeyCode(nil)
        
        if activeKeyTextField() != nil {
            updateActiveKeyTextField { keyTextField in
                guard keyTextField.isAllowModifierOnly else {
                    return
                }

                keyTextField.shortcut = KeyboardShortcut(keyCode: CGKeyCode(1000 + mediaKeyEvent.keyCode),
                                                         flags: mediaKeyEvent.flags)
                keyTextField.stringValue = keyTextField.shortcut!.toString()
            }

            return nil
        }
        
        if hasConvertedEvent(mediaKeyEvent.event, keyCode: CGKeyCode(1000 + mediaKeyEvent.keyCode)) {
            if let event = getConvertedEvent(mediaKeyEvent.event, keyCode: CGKeyCode(1000 + mediaKeyEvent.keyCode)) {
                print(KeyboardShortcut(event).toString())
                
                print(event.type == CGEventType.keyDown)
                event.post(tap: CGEventTapLocation.cghidEventTap)
            }
            return nil
        }
        
        return Unmanaged.passUnretained(mediaKeyEvent.event)
    }
    
    func mediaKeyUp(_ mediaKeyEvent: MediaKeyEvent) -> Unmanaged<CGEvent>? {
        // if hasConvertedEvent(mediaKeyEvent.event, keyCode: CGKeyCode(1000 + mediaKeyEvent.keyCode)) {
        //     if let event = getConvertedEvent(mediaKeyEvent.event, keyCode: CGKeyCode(1000 + Int(mediaKeyEvent.keyCode))) {
                // event.post(tap: CGEventTapLocation.cghidEventTap)
        //     }
        //     return nil
        // }
        
        return Unmanaged.passUnretained(mediaKeyEvent.event)
    }
    
    func hasConvertedEvent(_ event: CGEvent, keyCode: CGKeyCode? = nil) -> Bool {
        let shortcht = event.type.rawValue == UInt32(NX_SYSDEFINED) ?
            KeyboardShortcut(keyCode: 0, flags: MediaKeyEvent(event)!.flags) : KeyboardShortcut(event)
        
        if let mappingList = shortcutMappings(for: keyCode ?? shortcht.keyCode) {
            for mappings in mappingList {
                if shortcht.isCover(mappings.input) {
                    hasConvertedEventLog = mappings
                    return true
                }
            }
        }
        hasConvertedEventLog = nil
        return false
    }
    func getConvertedEvent(_ event: CGEvent, keyCode: CGKeyCode? = nil) -> CGEvent? {
        var event = event
        
        if event.type.rawValue == UInt32(NX_SYSDEFINED) {
            let flags = MediaKeyEvent(event)!.flags
            event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)!
            event.flags = flags
        }
        
        let shortcht = KeyboardShortcut(event)
        
        func getEvent(_ mappings: KeyMapping) -> CGEvent? {
            if mappings.output.keyCode == 999 {
                // 999 is Disable
                return nil
            }
            
            event.setIntegerValueField(.keyboardEventKeycode, value: Int64(mappings.output.keyCode))
            event.flags = CGEventFlags(
                rawValue: (event.flags.rawValue & ~mappings.input.flags.rawValue) | mappings.output.flags.rawValue
            )
            
            return event
        }
        
        if let mappingList = shortcutMappings(for: keyCode ?? shortcht.keyCode) {
            if let mappings = hasConvertedEventLog,
                shortcht.isCover(mappings.input) {
                
                return getEvent(mappings)
            }
            for mappings in mappingList {
                if shortcht.isCover(mappings.input) {
                    return getEvent(mappings)
                }
            }
        }
        return nil
    }
}

let modifierMasks: [CGKeyCode: CGEventFlags] = [
    54: CGEventFlags.maskCommand,
    55: CGEventFlags.maskCommand,
    56: CGEventFlags.maskShift,
    60: CGEventFlags.maskShift,
    59: CGEventFlags.maskControl,
    62: CGEventFlags.maskControl,
    58: CGEventFlags.maskAlternate,
    61: CGEventFlags.maskAlternate,
    63: CGEventFlags.maskSecondaryFn,
    57: CGEventFlags.maskAlphaShift
]
