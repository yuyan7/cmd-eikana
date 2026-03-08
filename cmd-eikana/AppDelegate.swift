//
//  AppDelegate.swift
//  ⌘英かな
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var windowController : NSWindowController?
    var preferenceWindowController: PreferenceWindowController!
    let keyEvent = KeyEvent()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let userDefaults = UserDefaults.standard
        
        // 「ログイン後にこのアプリを起動」
        if userDefaults.object(forKey: "launchAtStartup") == nil {
            setLaunchAtStartup(true)
            userDefaults.set(1, forKey: "launchAtStartup")
        }
        
        // 「起動時にアップデートを確認」
        let checkUpdateState = userDefaults.object(forKey: "checkUpdateAtLaunch")
        
        if checkUpdateState == nil {
            userDefaults.set(1, forKey: "checkUpdateAtLaunch")
            checkUpdate()
        }
        else if let state = checkUpdateState as? Int, state == 1 {
            checkUpdate()
        }
        
        // 除外アプリ設定
        if let exclusionAppsListData = userDefaults.object(forKey: "exclusionApps") as? [[AnyHashable: Any]] {
            for val in exclusionAppsListData {
                if let exclusionApps = AppData(dictionary: val) {
                    AppState.shared.addExcludedApp(exclusionApps)
                }
            }
        }
        
        // ショートカット設定
        if let keyMappingListData = userDefaults.object(forKey: "mappings") as? [[AnyHashable: Any]] {
            for val in keyMappingListData {
                if let mapping = KeyMapping(dictionary: val) {
                    AppState.shared.addKeyMapping(mapping)
                }
            }
        }
        else {
            if let oneShotModifiersData = userDefaults.object(forKey: "oneShotModifiers") as? [AnyObject] {
                // v2.0.xからの引き継ぎ
                for val in oneShotModifiersData {
                    if let inputKeyCodeInt = val["input"] as? Int,
                        let outputDic = val["output"] as? [AnyHashable: Any],
                        let output = KeyboardShortcut(dictionary: outputDic)
                    {
                        AppState.shared.addKeyMapping(KeyMapping(input: KeyboardShortcut(keyCode: CGKeyCode(inputKeyCodeInt)),
                                                                  output: output))
                    }
                }
                
                userDefaults.removeObject(forKey: "oneShotModifiers")
            }
            else {
                // 初期設定（左右のコマンドキー単体で英数/かな）
                AppState.shared.setKeyMappings([
                    KeyMapping(input: KeyboardShortcut(keyCode: 55), output: KeyboardShortcut(keyCode: 102)),
                    KeyMapping(input: KeyboardShortcut(keyCode: 54), output: KeyboardShortcut(keyCode: 104))
                ])
            }

            AppState.shared.saveKeyMappings()
        }
        
        preferenceWindowController = PreferenceWindowController.getInstance()
        
        let menu = NSMenu()
        AppState.shared.configureStatusItem(title: "⌘", menu: menu)
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        
        menu.addItem(withTitle: "About ⌘英かな \(version)", action: #selector(AppDelegate.open(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Preferences...", action: #selector(AppDelegate.openPreferencesSerector(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Restart", action: #selector(AppDelegate.restart(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Quit", action: #selector(AppDelegate.quit(_:)), keyEquivalent: "")
        
        keyEvent.start()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {}
    
    func applicationDidResignActive(_ notification: Notification) {
        AppState.shared.blurFocusedKeyField()
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        preferenceWindowController.showAndActivate(self)
        return false
    }
    
    // 保存されたUserDefaultを全削除する。
    func resetUserDefault() {
        let appDomain:String = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: appDomain)
    }
    
    @IBAction func open(_ sender: NSButton) {
        if let checkURL = URL(string: "https://ei-kana.appspot.com") {
            if NSWorkspace.shared.open(checkURL) {
                print("url successfully opened")
            }
        } else {
            print("invalid url")
        }
    }
    @IBAction func openPreferencesSerector(_ sender: NSButton) {
        preferenceWindowController.showAndActivate(self)
    }
    
    @IBAction func restart(_ sender: NSButton) {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().path
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = [path]
        do {
            try task.run()
        } catch {
            print("Failed to restart: \(error)")
        }
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func quit(_ sender: NSButton) {
        NSApplication.shared.terminate(self)
    }
}
