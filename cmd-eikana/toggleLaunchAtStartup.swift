//
//  toggleLaunchAtStartup.swift
//  ⌘英かな
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa
import ServiceManagement

func setLaunchAtStartup(_ enabled: Bool) {
    let service = SMAppService.mainApp
    do {
        if enabled {
            try service.register()
        } else {
            try service.unregister()
        }
        print(enabled ? "Successfully add login item." : "Successfully remove login item.")
    } catch {
        print("Failed to \(enabled ? "add" : "remove") login item: \(error)")
    }
}
