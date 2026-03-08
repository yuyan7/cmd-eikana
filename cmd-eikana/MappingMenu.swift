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
            AppState.shared.swapKeyMappings(at: row, and: row - 1)
        }
    }
    func move(_ at: Int) {
        if let row = self.row {
            AppState.shared.moveKeyMapping(from: row, to: at)
        }
    }
    func down() {
        if let row = self.row, row + 1 != AppState.shared.keyMappingCount() {
            AppState.shared.swapKeyMappings(at: row, and: row + 1)
        }
    }
    func remove() {
        AppState.shared.removeKeyMapping(at: self.row!)
    }
}
