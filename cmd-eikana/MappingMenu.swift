//
//  MappingMenu.swift
//  ⌘英かな
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

class MappingMenu: NSPopUpButton {
    var row: Int? = nil
    
    func up() {
        if let row = self.row, row - 1 != -1 {
            let keyMapping = AppState.shared.keyMappingList[row]
            
            AppState.shared.keyMappingList[row] = AppState.shared.keyMappingList[row - 1]
            AppState.shared.keyMappingList[row - 1] = keyMapping
        }
    }
    func move(_ at: Int) {
        var at = at
        if let row = self.row {
            let keyMapping = AppState.shared.keyMappingList[row]
            
            if at < 0 {
                at = 0
            }
            else if at > AppState.shared.keyMappingList.count - 1 {
                at = AppState.shared.keyMappingList.count - 1
            }
            
            AppState.shared.keyMappingList.remove(at: row)
            AppState.shared.keyMappingList.insert(keyMapping, at: at)
        }
    }
    func down() {
        if let row = self.row, row + 1 != AppState.shared.keyMappingList.count {
            let keyMapping = AppState.shared.keyMappingList[row]
            
            AppState.shared.keyMappingList[row] = AppState.shared.keyMappingList[row + 1]
            AppState.shared.keyMappingList[row + 1] = keyMapping
        }
    }
    func remove() {
        AppState.shared.keyMappingList.remove(at: self.row!)
    }
}
