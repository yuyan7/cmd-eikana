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
    
    private init() {}
    
    var statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
    
    var activeAppsList: [AppData] = []
    var exclusionAppsList: [AppData] = []
    var exclusionAppsDict: [String: String] = [:]
    
    var shortcutList: [CGKeyCode: [KeyMapping]] = [:]
    var keyMappingList: [KeyMapping] = []
    
    weak var activeKeyTextField: KeyTextField?
    
    func saveKeyMappings() {
        UserDefaults.standard.set(keyMappingList.map { $0.toDictionary() }, forKey: "mappings")
    }
    
    func keyMappingListToShortcutList() {
        shortcutList = [:]
        
        for val in keyMappingList {
            let key = val.input.keyCode
            
            if shortcutList[key] == nil {
                shortcutList[key] = []
            }
            
            shortcutList[key]?.append(val)
            
            #if DEBUG
                print("\(key): \(val.input.toString()) => \(val.output.toString())")
            #endif
        }
    }
    
    func saveExclusionApps() {
        UserDefaults.standard.set(exclusionAppsList.map { $0.toDictionary() }, forKey: "exclusionApps")
    }
    
    func rebuildExclusionAppsDict() {
        exclusionAppsDict = [:]
        for val in exclusionAppsList {
            exclusionAppsDict[val.id] = val.name
        }
    }
}
